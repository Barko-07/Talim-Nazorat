"""Login, two-factor authentication, logout and password management."""
from __future__ import annotations

import json
import math
import secrets
from datetime import timedelta

from fastapi import APIRouter, Depends, Request, Response
from sqlalchemy import delete, select, update
from sqlalchemy.orm import Session

from ..context import AppContext
from ..crypto import constant_time_equals, keyed_hash
from ..deps import ApiError, Principal, _authenticate, client_ip, get_ctx, get_db, require_partial
from ..models import OneTimeCode, PendingRegistration, RecoveryCode, User, _tz, utcnow
from ..schemas import (
    CodeIn,
    EmailCodeIn,
    LoginIn,
    PasswordChangeIn,
    PasswordConfirmIn,
    RecoveryCodeIn,
    RegisterIn,
    RegistrationIdIn,
    RegistrationVerifyIn,
    ResetConfirmIn,
    ResetRequestIn,
)
from ..security import audit, mfa, passwords, sessions

router = APIRouter(prefix="/api/auth", tags=["auth"])

GENERIC_LOGIN_ERROR = "Login yoki parol noto‘g‘ri, yoki hisob vaqtincha bloklangan"
MAX_LOCK = timedelta(hours=24)


def profile_of(user: User) -> dict:
    try:
        data = json.loads(user.profile or "{}")
    except ValueError:
        return {}
    return data if isinstance(data, dict) else {}


def _user_out(ctx: AppContext, p_session, user: User, **extra) -> dict:
    return {
        "state": sessions.session_state(ctx.settings, p_session),
        "csrf_token": sessions.csrf_token(p_session),
        "user": {
            "id": user.id,
            "email": user.email,
            "full_name": user.full_name,
            "role": user.role,
            "institution_id": user.institution_id,
            "phone": user.phone,
            "mfa_enabled": user.mfa_enabled,
            "can_remember_device": sessions.may_remember_device(ctx.settings, user),
            "profile": profile_of(user),
        },
        **extra,
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

    if user.pending_approval:
        # Told only to someone who knows the password.
        raise ApiError(403, "pending_approval",
                       "Hisobingiz administrator tasdig‘ini kutmoqda. Tasdiqlangach emailingizga xabar keladi.")

    user.failed_logins = 0
    user.locked_until = None
    if passwords.needs_rehash(user.password_hash):
        user.password_hash = passwords.hash_password(body.password)
    db.commit()

    if not user.mfa_enabled and sessions.trusted_device(db, s, user, request):
        sess = sessions.issue(db, s, user, request, response, mfa_verified=True, ip=ip, factor="device")
        audit.record(db, "LOGIN_OK", user_id=user.id, subject=audit.mask_login(email), ip=ip,
                     detail="password + remembered device")
        return _user_out(ctx, sess, user)

    sess = sessions.issue(db, s, user, request, response, mfa_verified=False, ip=ip)
    audit.record(db, "LOGIN_PASSWORD_OK", user_id=user.id, subject=audit.mask_login(email), ip=ip)
    if user.mfa_enabled:
        return _user_out(ctx, sess, user)
    # Second factor by email: the code goes out right away (unless one was sent
    # moments ago), so the user only has to open the mailbox.
    wait = _code_cooldown(db, ctx, user, "login")
    if wait == 0:
        _issue_code(db, ctx, user, "login")
        audit.record(db, "LOGIN_CODE_SENT", user_id=user.id, ip=ip)
        wait = s.code_resend_seconds
    return _user_out(ctx, sess, user, resend_after=wait)


@router.post("/email-code/send")
def email_code_send(request: Request, db: Session = Depends(get_db), ctx: AppContext = Depends(get_ctx)):
    """"Kodni qayta yuborish": a new login code, at most once a minute."""
    p = _authenticate(request, db, {"email_code_required"})
    wait = _code_cooldown(db, ctx, p.user, "login")
    if wait:
        raise ApiError(429, "resend_too_soon", f"Kodni {wait} soniyadan keyin qayta so‘rashingiz mumkin",
                       retry_after=wait)
    _too_many(ctx, db, f"login-code:{p.user.id}", 5, 900, p.ip, "login code resend")
    _issue_code(db, ctx, p.user, "login")
    audit.record(db, "LOGIN_CODE_SENT", user_id=p.user.id, ip=p.ip, detail="resend")
    return {"ok": True, "resend_after": ctx.settings.code_resend_seconds}


@router.post("/email-code/verify")
def email_code_verify(body: EmailCodeIn, request: Request, response: Response,
                      db: Session = Depends(get_db), ctx: AppContext = Depends(get_ctx)):
    p = _authenticate(request, db, {"email_code_required"})
    _too_many(ctx, db, f"email-code:{p.session.id}", 10, 300, p.ip, "login code attempts")
    user = p.user
    if not _consume_code(db, ctx, user, "login", body.code, p.ip):
        raise ApiError(401, "invalid_code", "Kod noto‘g‘ri yoki muddati o‘tgan")
    p.session.revoked = True  # privilege change: rotate the session token
    db.commit()
    sess = sessions.issue(db, ctx.settings, user, request, response, mfa_verified=True, ip=p.ip,
                          factor="email")
    if body.remember_device and sessions.may_remember_device(ctx.settings, user):
        sessions.remember_device(db, ctx.settings, user, request, response)
        audit.record(db, "DEVICE_REMEMBERED", user_id=user.id, ip=p.ip)
    audit.record(db, "LOGIN_OK", user_id=user.id, ip=p.ip, detail="password + email code")
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
    sess = sessions.issue(db, ctx.settings, user, request, response, mfa_verified=True, ip=ip,
                          factor="totp")
    audit.record(db, "LOGIN_OK", user_id=user.id, ip=ip, detail="password + 2FA")
    return _user_out(ctx, sess, user)


@router.post("/mfa/recovery")
def mfa_recovery(body: RecoveryCodeIn, request: Request, response: Response,
                 db: Session = Depends(get_db), ctx: AppContext = Depends(get_ctx)):
    """Lost phone: one of the single-use backup codes replaces the app code."""
    p = _authenticate(request, db, {"mfa_required"})
    _too_many(ctx, db, f"mfa:{p.session.id}", 5, 300, p.ip, "mfa attempts")
    user = p.user
    wanted = keyed_hash(f"recovery:{user.id}:{mfa.normalize_recovery_code(body.code)}")
    unused = db.scalars(
        select(RecoveryCode).where(RecoveryCode.user_id == user.id, RecoveryCode.used_at.is_(None))
    ).all()
    match = None
    for rc in unused:  # compare against all of them: timing does not reveal which matched
        if constant_time_equals(rc.code_hash, wanted):
            match = rc
    if match is None:
        audit.record(db, "MFA_RECOVERY_FAILED", severity="warning", user_id=user.id, ip=p.ip,
                     webhook_url=ctx.settings.alert_webhook_url)
        raise ApiError(401, "invalid_code", "Zaxira kod noto‘g‘ri yoki allaqachon ishlatilgan")
    match.used_at = utcnow()
    p.session.revoked = True
    db.commit()
    left = len(unused) - 1
    sess = sessions.issue(db, ctx.settings, user, request, response, mfa_verified=True, ip=p.ip,
                          factor="recovery")
    audit.record(db, "MFA_RECOVERY_USED", severity="warning", user_id=user.id, ip=p.ip,
                 detail=f"{left} left", webhook_url=ctx.settings.alert_webhook_url)
    ctx.mailer.send(user.email, "Individ: zaxira kod ishlatildi",
                    f"Hisobingizga zaxira kod bilan kirildi. Qolgan zaxira kodlar: {left} ta.\n"
                    "Agar bu siz bo‘lmasangiz, darhol administratorga murojaat qiling.")
    return _user_out(ctx, sess, user, recovery_codes_left=left)


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
    p = _authenticate(request, db, {"ok", "mfa_required", "email_code_required", "mfa_setup_required",
                                    "password_change_required"})
    extra = {}
    if sessions.session_state(ctx.settings, p.session) == "email_code_required":
        extra["resend_after"] = _code_cooldown(db, ctx, p.user, "login")
    return _user_out(ctx, p.session, p.user, **extra)


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
    codes = mfa.new_recovery_codes()
    db.execute(delete(RecoveryCode).where(RecoveryCode.user_id == user.id))
    for code in codes:
        db.add(RecoveryCode(user_id=user.id,
                            code_hash=keyed_hash(f"recovery:{user.id}:{mfa.normalize_recovery_code(code)}")))
    db.commit()
    sessions.forget_devices(db, user.id)  # from now on the authenticator is always asked
    sess = sessions.issue(db, ctx.settings, user, request, response, mfa_verified=True, ip=p.ip,
                          factor="totp")
    sessions.revoke_all(db, user.id, except_id=sess.id)
    audit.record(db, "MFA_ENABLED", user_id=user.id, ip=p.ip)
    ctx.mailer.send(user.email, "Individ: ikki bosqichli himoya yoqildi",
                    "Hisobingiz uchun ikki bosqichli himoya yoqildi. Agar bu siz bo‘lmasangiz, "
                    "darhol administratorga murojaat qiling.")
    # Shown once: only their HMACs are kept.
    return _user_out(ctx, sess, user, recovery_codes=codes)


# ------------------------------------------------------------------ one-time codes

CODE_PURPOSES = {
    "login": ("Individ: kirish kodi", "tizimga kirish"),
    "password_reset": ("Individ: tasdiqlash kodi", "parolni tiklash"),
    "password_change": ("Individ: tasdiqlash kodi", "parolni o‘zgartirish"),
}


def _code_mail(ctx: AppContext, what: str, code: str) -> str:
    return (
        f"Sizning {what} kodingiz: {code}\n\n"
        f"Kod {ctx.settings.code_ttl_minutes} daqiqa amal qiladi va faqat bir marta ishlatiladi.\n"
        "Agar bu so‘rovni siz yubormagan bo‘lsangiz, ushbu xatni e’tiborsiz qoldiring va "
        "administratorga xabar bering. Kodni hech kimga aytmang."
    )


def _code_cooldown(db: Session, ctx: AppContext, user: User, purpose: str) -> int:
    """Seconds until another code may be emailed (0 = now)."""
    last = db.scalar(
        select(OneTimeCode.created_at)
        .where(OneTimeCode.user_id == user.id, OneTimeCode.purpose == purpose)
        .order_by(OneTimeCode.created_at.desc())
        .limit(1)
    )
    if last is None:
        return 0
    passed = (utcnow() - _tz(last)).total_seconds()
    return max(0, math.ceil(ctx.settings.code_resend_seconds - passed))


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
    subject, what = CODE_PURPOSES[purpose]
    ctx.mailer.send(user.email, subject, _code_mail(ctx, what, code))


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
    sessions.forget_devices(db, user.id)  # a new password re-asks the emailed code everywhere


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
    # The forced change of a temporary password happens right after the login's
    # second factor, so no extra emailed code is asked for it.
    forced = user.must_change_password and p.session.mfa_verified
    if not forced and not (body.code and _consume_code(db, ctx, user, "password_change", body.code, p.ip)):
        raise ApiError(401, "invalid_credentials", "Joriy parol yoki kod noto‘g‘ri")
    _set_password(db, ctx, user, body.new_password)
    mfa_ok, factor = p.session.mfa_verified, p.session.factor
    p.session.revoked = True
    db.commit()
    sess = sessions.issue(db, ctx.settings, user, request, response, mfa_verified=mfa_ok, ip=p.ip,
                          factor=factor)
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


# ------------------------------------------------------------------ sign-up with email confirmation

MAX_REGISTRATION_SENDS = 5
REGISTRATION_SENT = "Tasdiqlash kodi emailingizga yuborildi"


def _registration_code(reg_id: str, code: str) -> str:
    return keyed_hash(f"register:{reg_id}:{code}")


def _new_code() -> str:
    return f"{secrets.randbelow(1_000_000):06d}"


@router.post("/register", status_code=202)
def register(body: RegisterIn, request: Request, db: Session = Depends(get_db),
             ctx: AppContext = Depends(get_ctx)):
    """Step 1 of sign-up. Answers the same way whether or not the email is
    already used, so the form cannot be used to discover accounts; the owner
    of an existing account gets a warning email instead of a code."""
    s = ctx.settings
    ip = client_ip(request)
    _too_many(ctx, db, f"register-ip:{ip}", 5, 3600, ip, "registrations per IP")
    email = body.email.lower()
    full_name = f"{body.last_name} {body.first_name}"
    problems = passwords.password_problems(body.password, email=email, full_name=full_name)
    if problems:
        raise ApiError(422, "weak_password", "; ".join(problems))

    now = utcnow()
    db.execute(delete(PendingRegistration).where(PendingRegistration.expires_at < now - timedelta(days=1)))
    existing = db.scalar(select(User).where(User.email == email))
    reg = PendingRegistration(email=email, code_hash="", data="{}",
                              expires_at=now + timedelta(minutes=s.code_ttl_minutes))
    db.add(reg)
    db.flush()
    if existing is not None:
        reg.data = json.dumps({"existing": True})
        reg.code_hash = _registration_code(reg.id, secrets.token_hex(16))  # can never match
        db.commit()
        audit.record(db, "REGISTER_EXISTING_EMAIL", severity="warning", user_id=existing.id,
                     subject=audit.mask_login(email), ip=ip, webhook_url=s.alert_webhook_url)
        ctx.mailer.send(email, "Individ: ro‘yxatdan o‘tishga urinish",
                        "Kimdir ushbu email bilan Individ’da yangi hisob ochmoqchi bo‘ldi. Sizda allaqachon "
                        "hisob bor, shuning uchun yangi hisob ochilmadi.\nParolingizni unutgan bo‘lsangiz, "
                        "kirish sahifasidagi “Parolni unutdingizmi?” orqali tiklang. Agar bu siz "
                        "bo‘lmasangiz, hech narsa qilish shart emas.")
    else:
        code = _new_code()
        reg.code_hash = _registration_code(reg.id, code)
        reg.data = json.dumps({
            "full_name": full_name,
            "phone": body.phone,
            "role": body.role.value,
            "password_hash": passwords.hash_password(body.password),
            "profile": {
                "first_name": body.first_name, "last_name": body.last_name,
                "specialization": body.specialization,
                "qualification_category": body.qualification_category,
                "experience_years": body.experience_years,
                "region": body.region, "district": body.district,
                "institution_name": body.institution_name,
            },
        })
        db.commit()
        audit.record(db, "REGISTER_CODE_SENT", subject=audit.mask_login(email), ip=ip)
        ctx.mailer.send(email, "Individ: emailni tasdiqlash", _code_mail(ctx, "ro‘yxatdan o‘tish", code))
    return {"registration_id": reg.id, "resend_after": s.code_resend_seconds, "message": REGISTRATION_SENT}


def _pending(db: Session, reg_id: str) -> PendingRegistration:
    reg = db.get(PendingRegistration, reg_id)
    if reg is None or _tz(reg.expires_at) < utcnow():
        raise ApiError(400, "registration_expired",
                       "Tasdiqlash muddati tugadi. Ro‘yxatdan o‘tishni qaytadan boshlang")
    return reg


@router.post("/register/resend")
def register_resend(body: RegistrationIdIn, request: Request, db: Session = Depends(get_db),
                    ctx: AppContext = Depends(get_ctx)):
    """"Kodni qayta yuborish" on the sign-up code screen."""
    s = ctx.settings
    ip = client_ip(request)
    _too_many(ctx, db, f"register-resend-ip:{ip}", 10, 3600, ip, "registration resends per IP")
    reg = _pending(db, body.registration_id)
    wait = max(0, math.ceil(s.code_resend_seconds - (utcnow() - _tz(reg.last_sent_at)).total_seconds()))
    if wait:
        raise ApiError(429, "resend_too_soon", f"Kodni {wait} soniyadan keyin qayta so‘rashingiz mumkin",
                       retry_after=wait)
    if reg.sends >= MAX_REGISTRATION_SENDS:
        raise ApiError(429, "rate_limited", "Juda ko‘p urinish. Ro‘yxatdan o‘tishni qaytadan boshlang")
    reg.sends += 1
    reg.attempts = 0
    reg.last_sent_at = utcnow()
    reg.expires_at = utcnow() + timedelta(minutes=s.code_ttl_minutes)
    data = json.loads(reg.data)
    if data.get("existing"):
        db.commit()  # same answer as a real resend; nothing is mailed
    else:
        code = _new_code()
        reg.code_hash = _registration_code(reg.id, code)
        db.commit()
        ctx.mailer.send(reg.email, "Individ: emailni tasdiqlash", _code_mail(ctx, "ro‘yxatdan o‘tish", code))
    return {"ok": True, "resend_after": s.code_resend_seconds, "message": REGISTRATION_SENT}


@router.post("/register/verify")
def register_verify(body: RegistrationVerifyIn, request: Request, db: Session = Depends(get_db),
                    ctx: AppContext = Depends(get_ctx)):
    """Step 2: the emailed code creates the account, which then waits for an
    administrator to approve it (and attach it to the right school)."""
    s = ctx.settings
    ip = client_ip(request)
    _too_many(ctx, db, f"register-verify-ip:{ip}", 20, 900, ip, "registration verify per IP")
    reg = _pending(db, body.registration_id)
    reg.attempts += 1
    if reg.attempts > s.code_max_attempts:
        db.commit()
        raise ApiError(429, "rate_limited", "Juda ko‘p noto‘g‘ri urinish. Yangi kod so‘rang")
    if not constant_time_equals(reg.code_hash, _registration_code(reg.id, body.code)):
        db.commit()
        audit.record(db, "REGISTER_CODE_FAILED", severity="warning", subject=audit.mask_login(reg.email), ip=ip)
        raise ApiError(400, "invalid_code", "Kod noto‘g‘ri yoki muddati o‘tgan")
    data = json.loads(reg.data)
    if db.scalar(select(User).where(User.email == reg.email)) is not None:  # taken meanwhile
        db.delete(reg)
        db.commit()
        raise ApiError(400, "invalid_code", "Kod noto‘g‘ri yoki muddati o‘tgan")
    user = User(
        email=reg.email, full_name=data["full_name"], role=data["role"], phone=data["phone"],
        password_hash=data["password_hash"], must_change_password=False, is_active=True,
        pending_approval=True, profile=json.dumps(data["profile"]),
    )
    db.add(user)
    db.delete(reg)
    db.commit()
    audit.record(db, "REGISTERED_PENDING_APPROVAL", user_id=user.id, subject=audit.mask_login(user.email), ip=ip)
    admins = db.scalars(select(User).where(User.role == "SUPER_ADMIN", User.is_active.is_(True))).all()
    for admin in admins:
        ctx.mailer.send(admin.email, "Individ: yangi ro‘yxatdan o‘tish",
                        f"{user.full_name} ({data['profile'].get('institution_name', '')}) ro‘yxatdan o‘tdi va "
                        "tasdiqlashingizni kutmoqda. Administrator panelida ko‘rib chiqing.")
    return {"ok": True, "message": "Email tasdiqlandi. Hisobingiz administrator tasdig‘idan so‘ng faollashadi"}
