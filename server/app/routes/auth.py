"""Login, two-factor authentication, logout and password management."""
from __future__ import annotations

import secrets
from datetime import timedelta

from fastapi import APIRouter, Depends, Request, Response
from sqlalchemy import select, update
from sqlalchemy.orm import Session

from ..context import AppContext
from ..crypto import constant_time_equals, keyed_hash
from ..deps import ApiError, Principal, _authenticate, client_ip, get_ctx, get_db, require_partial
from ..models import OneTimeCode, User, _tz, utcnow
from ..schemas import (
    CodeIn,
    LoginIn,
    PasswordChangeIn,
    PasswordConfirmIn,
    ResetConfirmIn,
    ResetRequestIn,
)
from ..security import audit, mfa, passwords, sessions

router = APIRouter(prefix="/api/auth", tags=["auth"])

GENERIC_LOGIN_ERROR = "Login yoki parol noto‘g‘ri, yoki hisob vaqtincha bloklangan"
MAX_LOCK = timedelta(hours=24)


def _user_out(ctx: AppContext, p_session, user: User) -> dict:
    return {
        "state": sessions.session_state(ctx.settings, p_session),
        "csrf_token": sessions.csrf_token(p_session),
        "user": {
            "id": user.id,
            "email": user.email,
            "full_name": user.full_name,
            "role": user.role,
            "institution_id": user.institution_id,
            "mfa_enabled": user.mfa_enabled,
        },
    }


def _too_many(ctx: AppContext, db: Session, key: str, limit: int, window: int, ip: str, what: str) -> None:
    if not ctx.db_limiter.hit(db, key, limit, window):
        audit.record(db, "RATE_LIMITED", severity="warning", ip=ip, detail=what,
                     webhook_url=ctx.settings.alert_webhook_url)
        raise ApiError(429, "rate_limited", "Juda ko‘p urinish. Birozdan so‘ng qayta urinib ko‘ring")


# ------------------------------------------------------------------ login

@router.post("/login")
def login(
    body: LoginIn,
    request: Request,
    response: Response,
    db: Session = Depends(get_db),
    ctx: AppContext = Depends(get_ctx),
):
    s = ctx.settings
    ip = client_ip(request)
    _too_many(ctx, db, f"login-ip:{ip}", s.login_ip_per_minute, 60, ip, "login per IP")

    email = body.email.lower()
    user = db.scalar(select(User).where(User.email == email))
    now = utcnow()

    if user is None:
        passwords.verify_password(body.password, passwords.DUMMY_HASH)  # equal timing
        audit.record(db, "LOGIN_FAILED", severity="warning", subject=audit.mask_login(email), ip=ip,
                     detail="unknown account", webhook_url=s.alert_webhook_url)
        raise ApiError(401, "invalid_credentials", GENERIC_LOGIN_ERROR)

    if user.locked_now(now):
        passwords.verify_password(body.password, passwords.DUMMY_HASH)
        audit.record(db, "LOGIN_WHILE_LOCKED", severity="warning", user_id=user.id,
                     subject=audit.mask_login(email), ip=ip, webhook_url=s.alert_webhook_url)
        raise ApiError(401, "invalid_credentials", GENERIC_LOGIN_ERROR)

    if not passwords.verify_password(body.password, user.password_hash):
        user.failed_logins += 1
        if user.failed_logins >= s.login_max_failures:
            # Exponential lockout: 15 min, 30 min, 60 min ... capped at 24 h
            factor = 2 ** (user.failed_logins - s.login_max_failures)
            user.locked_until = now + min(timedelta(minutes=s.login_lock_minutes * factor), MAX_LOCK)
            db.commit()
            audit.record(db, "ACCOUNT_LOCKED", severity="alert", user_id=user.id,
                         subject=audit.mask_login(email), ip=ip,
                         detail=f"{user.failed_logins} failed logins", webhook_url=s.alert_webhook_url)
        else:
            db.commit()
            audit.record(db, "LOGIN_FAILED", severity="warning", user_id=user.id,
                         subject=audit.mask_login(email), ip=ip, webhook_url=s.alert_webhook_url)
        raise ApiError(401, "invalid_credentials", GENERIC_LOGIN_ERROR)

    if not user.is_active:
        audit.record(db, "LOGIN_BLOCKED_ACCOUNT", severity="warning", user_id=user.id,
                     subject=audit.mask_login(email), ip=ip, webhook_url=s.alert_webhook_url)
        raise ApiError(401, "invalid_credentials", GENERIC_LOGIN_ERROR)

    user.failed_logins = 0
    user.locked_until = None
    if passwords.needs_rehash(user.password_hash):
        user.password_hash = passwords.hash_password(body.password)
    db.commit()

    sess = sessions.issue(db, s, user, request, response, mfa_verified=False, ip=ip)
    audit.record(db, "LOGIN_PASSWORD_OK", user_id=user.id, subject=audit.mask_login(email), ip=ip)
    return _user_out(ctx, sess, user)


@router.post("/mfa/verify")
def mfa_verify(
    body: CodeIn,
    request: Request,
    response: Response,
    db: Session = Depends(get_db),
    ctx: AppContext = Depends(get_ctx),
):
    p = _authenticate(request, db, {"mfa_required"})
    ip = p.ip
    _too_many(ctx, db, f"mfa:{p.session.id}", 5, 300, ip, "mfa attempts")
    user = p.user
    step = mfa.verify(user.mfa_secret or "", body.code, user.mfa_last_step)
    if step is None:
        audit.record(db, "MFA_FAILED", severity="warning", user_id=user.id, ip=ip,
                     webhook_url=ctx.settings.alert_webhook_url)
        raise ApiError(401, "invalid_code", "Kod noto‘g‘ri")
    user.mfa_last_step = step
    p.session.revoked = True  # privilege change: rotate the session token
    db.commit()
    sess = sessions.issue(db, ctx.settings, user, request, response, mfa_verified=True, ip=ip)
    audit.record(db, "LOGIN_OK", user_id=user.id, ip=ip, detail="password + 2FA")
    return _user_out(ctx, sess, user)


@router.post("/logout")
def logout(request: Request, response: Response, db: Session = Depends(get_db),
           ctx: AppContext = Depends(get_ctx)):
    s = sessions.load(db, ctx.settings, request)
    if s is not None:
        s.revoked = True
        db.commit()
        audit.record(db, "LOGOUT", user_id=s.user_id, ip=client_ip(request))
    sessions.clear_cookie(ctx.settings, response)
    return {"ok": True}


@router.get("/me")
def me(request: Request, db: Session = Depends(get_db), ctx: AppContext = Depends(get_ctx)):
    p = _authenticate(request, db, {"ok", "mfa_required", "mfa_setup_required", "password_change_required"})
    return _user_out(ctx, p.session, p.user)


# ------------------------------------------------------------------ MFA setup

@router.post("/mfa/setup")
def mfa_setup(body: PasswordConfirmIn, p: Principal = Depends(require_partial),
              db: Session = Depends(get_db), ctx: AppContext = Depends(get_ctx)):
    """Step 1: re-enter password, receive a new secret to add to an authenticator app."""
    _too_many(ctx, db, f"mfa-setup:{p.user.id}", 5, 900, p.ip, "mfa setup")
    if not passwords.verify_password(body.password, p.user.password_hash):
        audit.record(db, "MFA_SETUP_BAD_PASSWORD", severity="warning", user_id=p.user.id, ip=p.ip,
                     webhook_url=ctx.settings.alert_webhook_url)
        raise ApiError(401, "invalid_credentials", "Parol noto‘g‘ri")
    if p.user.mfa_enabled:
        raise ApiError(409, "mfa_already_enabled", "Ikki bosqichli himoya allaqachon yoqilgan")
    secret = mfa.new_secret()
    p.user.mfa_secret = secret
    db.commit()
    return {"secret": secret, "otpauth_uri": mfa.provisioning_uri(secret, p.user.email)}


@router.post("/mfa/enable")
def mfa_enable(body: CodeIn, request: Request, response: Response,
               p: Principal = Depends(require_partial), db: Session = Depends(get_db),
               ctx: AppContext = Depends(get_ctx)):
    """Step 2: confirm the first code from the authenticator app."""
    _too_many(ctx, db, f"mfa-enable:{p.user.id}", 5, 300, p.ip, "mfa enable")
    user = p.user
    if user.mfa_enabled or not user.mfa_secret:
        raise ApiError(409, "mfa_setup_missing", "Avval sozlashni boshlang")
    step = mfa.verify(user.mfa_secret, body.code, user.mfa_last_step)
    if step is None:
        raise ApiError(401, "invalid_code", "Kod noto‘g‘ri")
    user.mfa_enabled = True
    user.mfa_last_step = step
    p.session.revoked = True
    db.commit()
    sess = sessions.issue(db, ctx.settings, user, request, response, mfa_verified=True, ip=p.ip)
    sessions.revoke_all(db, user.id, except_id=sess.id)
    audit.record(db, "MFA_ENABLED", user_id=user.id, ip=p.ip)
    ctx.mailer.send(user.email, "Individ: ikki bosqichli himoya yoqildi",
                    "Hisobingiz uchun ikki bosqichli himoya yoqildi. Agar bu siz bo‘lmasangiz, "
                    "darhol administratorga murojaat qiling.")
    return _user_out(ctx, sess, user)


# ------------------------------------------------------------------ one-time codes

def _issue_code(db: Session, ctx: AppContext, user: User, purpose: str) -> None:
    db.execute(
        update(OneTimeCode)
        .where(OneTimeCode.user_id == user.id, OneTimeCode.purpose == purpose, OneTimeCode.used.is_(False))
        .values(used=True)
    )
    code = f"{secrets.randbelow(1_000_000):06d}"
    db.add(OneTimeCode(
        user_id=user.id, purpose=purpose, code_hash=keyed_hash(f"{purpose}:{user.id}:{code}"),
        expires_at=utcnow() + timedelta(minutes=ctx.settings.code_ttl_minutes),
    ))
    db.commit()
    what = "parolni tiklash" if purpose == "password_reset" else "parolni o‘zgartirish"
    ctx.mailer.send(
        user.email,
        "Individ: tasdiqlash kodi",
        f"Sizning {what} kodingiz: {code}\n\n"
        f"Kod {ctx.settings.code_ttl_minutes} daqiqa amal qiladi va faqat bir marta ishlatiladi.\n"
        "Agar bu so‘rovni siz yubormagan bo‘lsangiz, ushbu xatni e’tiborsiz qoldiring va "
        "administratorga xabar bering. Kodni hech kimga aytmang.",
    )


def _consume_code(db: Session, ctx: AppContext, user: User, purpose: str, code: str, ip: str) -> bool:
    otc = db.scalar(
        select(OneTimeCode)
        .where(OneTimeCode.user_id == user.id, OneTimeCode.purpose == purpose, OneTimeCode.used.is_(False))
        .order_by(OneTimeCode.created_at.desc())
    )
    if otc is None or _tz(otc.expires_at) < utcnow():
        return False
    otc.attempts += 1
    if otc.attempts > ctx.settings.code_max_attempts:
        otc.used = True
        db.commit()
        audit.record(db, "CODE_ATTEMPTS_EXCEEDED", severity="alert", user_id=user.id, ip=ip,
                     detail=purpose, webhook_url=ctx.settings.alert_webhook_url)
        return False
    if not constant_time_equals(otc.code_hash, keyed_hash(f"{purpose}:{user.id}:{code}")):
        db.commit()
        audit.record(db, "CODE_FAILED", severity="warning", user_id=user.id, ip=ip, detail=purpose,
                     webhook_url=ctx.settings.alert_webhook_url)
        return False
    otc.used = True
    db.commit()
    return True


def _set_password(db: Session, ctx: AppContext, user: User, new_password: str) -> None:
    problems = passwords.password_problems(new_password, email=user.email, full_name=user.full_name)
    if passwords.verify_password(new_password, user.password_hash):
        problems.append("Yangi parol avvalgisidan farq qilishi kerak")
    if problems:
        raise ApiError(422, "weak_password", "; ".join(problems))
    user.password_hash = passwords.hash_password(new_password)
    user.must_change_password = False
    user.password_changed_at = utcnow()
    user.failed_logins = 0
    user.locked_until = None
    db.commit()


# ------------------------------------------------------------------ change password (logged in)

@router.post("/password/change/request")
def password_change_request(p: Principal = Depends(require_partial), db: Session = Depends(get_db),
                            ctx: AppContext = Depends(get_ctx)):
    """Emails a 6-digit code; required together with the current password."""
    _too_many(ctx, db, f"code:{p.user.id}", 3, 900, p.ip, "change code request")
    _issue_code(db, ctx, p.user, "password_change")
    audit.record(db, "PASSWORD_CHANGE_CODE_SENT", user_id=p.user.id, ip=p.ip)
    return {"ok": True}


@router.post("/password/change")
def password_change(body: PasswordChangeIn, request: Request, response: Response,
                    p: Principal = Depends(require_partial), db: Session = Depends(get_db),
                    ctx: AppContext = Depends(get_ctx)):
    _too_many(ctx, db, f"pwchange:{p.user.id}", 5, 900, p.ip, "password change")
    user = p.user
    if not passwords.verify_password(body.current_password, user.password_hash):
        audit.record(db, "PASSWORD_CHANGE_BAD_PASSWORD", severity="warning", user_id=user.id,
                     ip=p.ip, webhook_url=ctx.settings.alert_webhook_url)
        raise ApiError(401, "invalid_credentials", "Joriy parol yoki kod noto‘g‘ri")
    if not _consume_code(db, ctx, user, "password_change", body.code, p.ip):
        raise ApiError(401, "invalid_credentials", "Joriy parol yoki kod noto‘g‘ri")
    _set_password(db, ctx, user, body.new_password)
    mfa_ok = p.session.mfa_verified
    p.session.revoked = True
    db.commit()
    sess = sessions.issue(db, ctx.settings, user, request, response, mfa_verified=mfa_ok, ip=p.ip)
    sessions.revoke_all(db, user.id, except_id=sess.id)  # sign out every other device
    audit.record(db, "PASSWORD_CHANGED", user_id=user.id, ip=p.ip)
    ctx.mailer.send(user.email, "Individ: parol o‘zgartirildi",
                    "Hisobingiz paroli o‘zgartirildi va boshqa qurilmalardagi seanslar yopildi. "
                    "Agar bu siz bo‘lmasangiz, darhol administratorga murojaat qiling.")
    return _user_out(ctx, sess, user)


# ------------------------------------------------------------------ forgot password

@router.post("/password/reset/request", status_code=202)
def password_reset_request(body: ResetRequestIn, request: Request, db: Session = Depends(get_db),
                           ctx: AppContext = Depends(get_ctx)):
    """Always answers the same way, so it cannot be used to find accounts."""
    ip = client_ip(request)
    email = body.email.lower()
    _too_many(ctx, db, f"reset-ip:{ip}", 5, 900, ip, "reset per IP")
    user = db.scalar(select(User).where(User.email == email))
    if user is not None and user.is_active and ctx.db_limiter.hit(db, f"reset-user:{user.id}", 3, 3600):
        _issue_code(db, ctx, user, "password_reset")
        audit.record(db, "PASSWORD_RESET_CODE_SENT", user_id=user.id, subject=audit.mask_login(email), ip=ip)
    else:
        audit.record(db, "PASSWORD_RESET_IGNORED", subject=audit.mask_login(email), ip=ip)
    return {"ok": True, "message": "Agar hisob mavjud bo‘lsa, tasdiqlash kodi emailga yuborildi"}


@router.post("/password/reset/confirm")
def password_reset_confirm(body: ResetConfirmIn, request: Request, response: Response,
                           db: Session = Depends(get_db), ctx: AppContext = Depends(get_ctx)):
    ip = client_ip(request)
    _too_many(ctx, db, f"reset-confirm-ip:{ip}", 10, 900, ip, "reset confirm per IP")
    user = db.scalar(select(User).where(User.email == body.email.lower()))
    if user is None or not user.is_active or not _consume_code(db, ctx, user, "password_reset", body.code, ip):
        raise ApiError(400, "invalid_code", "Kod noto‘g‘ri yoki muddati o‘tgan")
    _set_password(db, ctx, user, body.new_password)
    sessions.revoke_all(db, user.id)
    sessions.clear_cookie(ctx.settings, response)
    audit.record(db, "PASSWORD_RESET", severity="warning", user_id=user.id, ip=ip,
                 webhook_url=ctx.settings.alert_webhook_url)
    ctx.mailer.send(user.email, "Individ: parol tiklandi",
                    "Hisobingiz paroli tiklandi va barcha seanslar yopildi. Agar bu siz bo‘lmasangiz, "
                    "darhol administratorga murojaat qiling.")
    return {"ok": True}
