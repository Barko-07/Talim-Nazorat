"""Login, two-factor authentication, logout and password management."""
from __future__ import annotations

import json
import math
import secrets
import uuid
from datetime import timedelta

from fastapi import APIRouter, Depends, Request, Response
from sqlalchemy import delete, func, select, update
from sqlalchemy.orm import Session

from .. import identity
from ..context import AppContext
from ..crypto import constant_time_equals, keyed_hash
from ..deps import ApiError, Principal, _authenticate, client_ip, get_ctx, get_db, require_partial, require_user
from ..mailer import MailError
from ..models import (
    Institution,
    Record,
    OneTimeCode,
    PendingRegistration,
    RecordChange,
    RecoveryCode,
    StudentAccess,
    User,
    _tz,
    utcnow,
)
from ..schemas import (
    CodeIn,
    EmailCodeIn,
    LoginIn,
    PasswordChangeIn,
    PasswordConfirmIn,
    ProfileUpdateIn,
    RecoveryCodeIn,
    RegisterIn,
    RegistrationIdIn,
    RegistrationVerifyIn,
    ResetConfirmIn,
    ResetRequestIn,
)
from ..security import audit, mfa, passwords, sessions

router = APIRouter(prefix="/api/auth", tags=["auth"])

# The same answer for a wrong password, an unknown email and a locked account,
# so the form cannot be used to find out which emails have accounts.
GENERIC_LOGIN_ERROR = "Login yoki parol noto‘g‘ri"
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
            # The school the account actually belongs to (the sign-up form's
            # free-text school name may differ from it).
            "institution_name": user.institution.name if user.institution else None,
            "phone": user.phone,
            "mfa_enabled": user.mfa_enabled,
            "can_stay_signed_in": sessions.may_stay_signed_in(ctx.settings, user),
            "profile": profile_of(user),
        },
        "remembered": bool(p_session.remember),
        **extra,
    }


MAIL_FAILED = "Xat yuborilmadi. Birozdan so‘ng qayta urinib ko‘ring"


def notify(db: Session, ctx: AppContext, to: str, subject: str, body: str, user_id: str | None = None) -> bool:
    """Security notices and other mail whose loss must not undo the action:
    a failure is logged as an alert instead of failing the request."""
    try:
        ctx.mailer.send(to, subject, body)
        return True
    except MailError:
        audit.record(db, "MAIL_FAILED", severity="alert", user_id=user_id, subject=audit.mask_login(to),
                     detail=subject[:120], webhook_url=ctx.settings.alert_webhook_url)
        return False


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
    user = identity.find_by_email(db, email)
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

    # Wrong passwords from one address shut that address out for 15 minutes;
    # only many more from everywhere lock the account itself - so a stranger
    # who knows someone's email cannot lock that person out from one place.
    ip_key = f"login-fail:{user.id}:{ip}"
    if ctx.db_limiter.count(db, ip_key, 900) >= s.login_max_failures:
        passwords.verify_password(body.password, passwords.DUMMY_HASH)
        audit.record(db, "LOGIN_WHILE_LOCKED", severity="warning", user_id=user.id,
                     subject=audit.mask_login(email), ip=ip, detail="this address",
                     webhook_url=s.alert_webhook_url)
        raise ApiError(401, "invalid_credentials", GENERIC_LOGIN_ERROR)

    if not passwords.verify_password(body.password, user.password_hash):
        ctx.db_limiter.hit(db, ip_key, s.login_max_failures, 900)
        user.failed_logins += 1
        if user.failed_logins >= s.login_account_max_failures:
            # Exponential lockout: 15 min, 30 min, 60 min ... capped at 24 h
            factor = 2 ** (user.failed_logins - s.login_account_max_failures)
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
        # Sign-ups no longer wait for an administrator: an account left from the
        # old approval step joins the school it chose and simply signs in.
        if user.institution_id is None:
            school = _school_by_name(db, profile_of(user).get("institution_name", ""))
            user.institution_id = school.id if school else None
        user.pending_approval = False
        audit.record(db, "SIGNUP_AUTO_ACTIVATED", user_id=user.id, subject=audit.mask_login(email), ip=ip)

    user.failed_logins = 0
    user.locked_until = None
    if passwords.needs_rehash(user.password_hash):
        user.password_hash = passwords.hash_password(body.password)
    db.commit()

    # Every sign-in is confirmed with a second factor (emailed code or the
    # authenticator). "Eslab qolish" applies once that is done.
    sess = sessions.issue(db, s, user, request, response, mfa_verified=False, ip=ip)
    if body.remember and sessions.may_stay_signed_in(s, user):
        sess.factor = sessions.WANTS_REMEMBER
        db.commit()
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
                          factor="email",
                          remember=p.session.factor == sessions.WANTS_REMEMBER)
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
                          factor="totp",
                          remember=p.session.factor == sessions.WANTS_REMEMBER)
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
                          factor="recovery",
                          remember=p.session.factor == sessions.WANTS_REMEMBER)
    audit.record(db, "MFA_RECOVERY_USED", severity="warning", user_id=user.id, ip=p.ip,
                 detail=f"{left} left", webhook_url=ctx.settings.alert_webhook_url)
    notify(db, ctx, user.email, "Individ: zaxira kod ishlatildi",
                    f"Hisobingizga zaxira kod bilan kirildi. Qolgan zaxira kodlar: {left} ta.\n"
                    "Agar bu siz bo‘lmasangiz, darhol administratorga murojaat qiling.", user.id)
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


# ------------------------------------------------------------------ own profile


def _split_name(full_name: str) -> tuple[str, str]:
    parts = full_name.split(maxsplit=1)
    return (parts[0], parts[1]) if len(parts) == 2 else (full_name, "")


@router.patch("/profile")
def update_profile(body: ProfileUpdateIn, p: Principal = Depends(require_user), db: Session = Depends(get_db),
                   ctx: AppContext = Depends(get_ctx)):
    """A person updates their own details - nobody else's. Each change is kept
    in the history administrators read (old and new values, encrypted)."""
    user = p.user
    profile = profile_of(user)
    last, first = _split_name(user.full_name)
    before = {**profile, "full_name": user.full_name, "phone": user.phone}
    changes = body.model_dump(exclude_unset=True)
    for key in ("specialization", "qualification_category", "experience_years", "region", "district",
                "middle_name"):
        if key in changes:
            profile[key] = changes[key]
    first = changes.get("first_name") or profile.get("first_name") or first
    last = changes.get("last_name") or profile.get("last_name") or last
    profile["first_name"], profile["last_name"] = first, last
    user.full_name = f"{last} {first}".strip()[:120]
    if "phone" in changes:
        if identity.phone_taken(db, changes["phone"], except_user_id=user.id):
            raise ApiError(409, "phone_taken", "Bu telefon raqami bilan hisob allaqachon bor")
        user.phone = changes["phone"]
    user.profile = json.dumps(profile, ensure_ascii=False)
    after = {**profile, "full_name": user.full_name, "phone": user.phone}
    keys = sorted(k for k in set(before) | set(after) if before.get(k) != after.get(k))
    if keys:
        # Which fields changed - not their values: the history can never be
        # erased, while a deleted account's name and phone must be.
        db.add(RecordChange(
            user_id=user.id, kind="profile", rid=user.id, institution_id=user.institution_id,
            action="update", fields=",".join(keys)[:1000],
        ))
    db.commit()
    audit.record(db, "PROFILE_UPDATED", user_id=user.id, ip=p.ip, detail=",".join(keys)[:400])
    return _user_out(ctx, p.session, user)


# ------------------------------------------------------------------ deleting one's account


@router.post("/account/delete")
def delete_account(body: PasswordConfirmIn, request: Request, response: Response,
                   p: Principal = Depends(require_user), db: Session = Depends(get_db),
                   ctx: AppContext = Depends(get_ctx)):
    """The person closes their own account (required by app stores). Personal
    data - name, email, phone, profile, 2FA - is erased at once and the login
    stops working. Work recorded about children stays with the school (it is
    the school's record, kept by law), attributed to "deleted user"."""
    _too_many(ctx, db, f"account-delete:{p.user.id}", 5, 900, p.ip, "account delete")
    user = p.user
    if not passwords.verify_password(body.password, user.password_hash):
        audit.record(db, "ACCOUNT_DELETE_BAD_PASSWORD", severity="warning", user_id=user.id, ip=p.ip,
                     webhook_url=ctx.settings.alert_webhook_url)
        raise ApiError(401, "invalid_credentials", "Parol noto‘g‘ri")
    if user.role == "SUPER_ADMIN":
        others = db.scalar(select(func.count()).select_from(User).where(
            User.role == "SUPER_ADMIN", User.is_active.is_(True), User.id != user.id))
        if not others:
            raise ApiError(409, "last_admin", "Oxirgi tizim administratori hisobini o‘chirib bo‘lmaydi")
    email = user.email
    notify(db, ctx, email, "Individ: hisobingiz o‘chirildi",
           "Hisobingiz va shaxsiy ma’lumotlaringiz o‘chirildi. Bolalar bo‘yicha kiritgan ish yozuvlaringiz "
           "maktab hujjati sifatida saqlanib qoladi. Agar bu siz bo‘lmasangiz, darhol administratorga "
           "murojaat qiling.", user.id)
    user.full_name = "O‘chirilgan foydalanuvchi"
    user.email = f"deleted-{user.id}@deleted.invalid"
    user.phone = None
    user.profile = None
    user.mfa_enabled, user.mfa_secret = False, None
    user.password_hash = passwords.hash_password(secrets.token_urlsafe(32))
    user.is_active = False
    user.pending_approval = False
    db.execute(delete(RecoveryCode).where(RecoveryCode.user_id == user.id))
    db.execute(delete(StudentAccess).where(StudentAccess.user_id == user.id))
    db.execute(delete(OneTimeCode).where(OneTimeCode.user_id == user.id))
    db.commit()
    sessions.revoke_all(db, user.id)
    sessions.clear_cookie(ctx.settings, response)
    audit.record(db, "ACCOUNT_DELETED", severity="warning", user_id=user.id, ip=p.ip,
                 subject=audit.mask_login(email))
    return {"ok": True}


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
    sess = sessions.issue(db, ctx.settings, user, request, response, mfa_verified=True, ip=p.ip,
                          factor="totp")
    sessions.revoke_all(db, user.id, except_id=sess.id)
    audit.record(db, "MFA_ENABLED", user_id=user.id, ip=p.ip)
    notify(db, ctx, user.email, "Individ: ikki bosqichli himoya yoqildi",
           "Hisobingiz uchun ikki bosqichli himoya yoqildi. Agar bu siz bo‘lmasangiz, "
           "darhol administratorga murojaat qiling.", user.id)
    # Shown once: only their HMACs are kept.
    return _user_out(ctx, sess, user, recovery_codes=codes)


# ------------------------------------------------------------------ one-time codes

CODE_PURPOSES = {
    "login": ("kirish kodi", "tizimga kirish"),
    "password_reset": ("parolni tiklash kodi", "parolni tiklash"),
    "password_change": ("parolni o‘zgartirish kodi", "parolni o‘zgartirish"),
}


def _code_subject(code: str, what: str) -> str:
    # The code is in the subject so every code arrives as its own email: mail
    # apps group messages with the same subject into one conversation.
    return f"{code} — Individ {what}"


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


def _issue_code(db: Session, ctx: AppContext, user: User, purpose: str, *, quiet: bool = False) -> None:
    """Emails a new code (older ones stop working). If the mail cannot be sent
    the code is cancelled at once, so asking again is not blocked by the resend
    gap; `quiet` callers must not reveal the failure (password reset)."""
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
    try:
        ctx.mailer.send(user.email, _code_subject(code, subject), _code_mail(ctx, what, code))
    except MailError:
        db.execute(delete(OneTimeCode).where(OneTimeCode.user_id == user.id, OneTimeCode.purpose == purpose,
                                             OneTimeCode.used.is_(False)))
        db.commit()
        audit.record(db, "MAIL_FAILED", severity="alert", user_id=user.id, detail=purpose,
                     webhook_url=ctx.settings.alert_webhook_url)
        if not quiet:
            raise ApiError(503, "mail_failed", MAIL_FAILED) from None


def _consume_code(db: Session, ctx: AppContext, user: User, purpose: str, code: str, ip: str) -> bool:
    # A daily cap per account on top of the per-code attempts: new codes can be
    # requested every minute, so without it a code could be guessed over weeks.
    daily_key = f"code-fail:{user.id}"
    if ctx.db_limiter.count(db, daily_key, 86400) >= ctx.settings.code_daily_failures:
        audit.record(db, "CODE_DAILY_LIMIT", severity="alert", user_id=user.id, ip=ip, detail=purpose,
                     webhook_url=ctx.settings.alert_webhook_url)
        return False
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
        ctx.db_limiter.hit(db, daily_key, ctx.settings.code_daily_failures, 86400)
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
    # The forced change of a temporary password happens right after the login's
    # second factor, so no extra emailed code is asked for it.
    forced = user.must_change_password and p.session.mfa_verified
    if not forced and not (body.code and _consume_code(db, ctx, user, "password_change", body.code, p.ip)):
        raise ApiError(401, "invalid_credentials", "Joriy parol yoki kod noto‘g‘ri")
    _set_password(db, ctx, user, body.new_password)
    mfa_ok, factor, remember = p.session.mfa_verified, p.session.factor, p.session.remember
    p.session.revoked = True
    db.commit()
    sess = sessions.issue(db, ctx.settings, user, request, response, mfa_verified=mfa_ok, ip=p.ip,
                          factor=factor, remember=remember)
    sessions.revoke_all(db, user.id, except_id=sess.id)  # sign out every other device
    audit.record(db, "PASSWORD_CHANGED", user_id=user.id, ip=p.ip)
    notify(db, ctx, user.email, "Individ: parol o‘zgartirildi",
           "Hisobingiz paroli o‘zgartirildi va boshqa qurilmalardagi seanslar yopildi. "
           "Agar bu siz bo‘lmasangiz, darhol administratorga murojaat qiling.", user.id)
    return _user_out(ctx, sess, user)


# ------------------------------------------------------------------ forgot password

@router.post("/password/reset/request", status_code=202)
def password_reset_request(body: ResetRequestIn, request: Request, db: Session = Depends(get_db),
                           ctx: AppContext = Depends(get_ctx)):
    """Always answers the same way, so it cannot be used to find accounts."""
    ip = client_ip(request)
    email = body.email.lower()
    _too_many(ctx, db, f"reset-ip:{ip}", 5, 900, ip, "reset per IP")
    user = identity.find_by_email(db, email)
    if user is not None and user.is_active and ctx.db_limiter.hit(db, f"reset-user:{user.id}", 3, 3600):
        _issue_code(db, ctx, user, "password_reset", quiet=True)
        audit.record(db, "PASSWORD_RESET_CODE_SENT", user_id=user.id, subject=audit.mask_login(email), ip=ip)
    else:
        audit.record(db, "PASSWORD_RESET_IGNORED", subject=audit.mask_login(email), ip=ip)
    return {"ok": True, "message": "Agar hisob mavjud bo‘lsa, tasdiqlash kodi emailga yuborildi"}


@router.post("/password/reset/confirm")
def password_reset_confirm(body: ResetConfirmIn, request: Request, response: Response,
                           db: Session = Depends(get_db), ctx: AppContext = Depends(get_ctx)):
    ip = client_ip(request)
    _too_many(ctx, db, f"reset-confirm-ip:{ip}", 10, 900, ip, "reset confirm per IP")
    user = identity.find_by_email(db, body.email)
    if user is None or not user.is_active or not _consume_code(db, ctx, user, "password_reset", body.code, ip):
        raise ApiError(400, "invalid_code", "Kod noto‘g‘ri yoki muddati o‘tgan")
    _set_password(db, ctx, user, body.new_password)
    sessions.revoke_all(db, user.id)
    sessions.clear_cookie(ctx.settings, response)
    audit.record(db, "PASSWORD_RESET", severity="warning", user_id=user.id, ip=ip,
                 webhook_url=ctx.settings.alert_webhook_url)
    notify(db, ctx, user.email, "Individ: parol tiklandi",
           "Hisobingiz paroli tiklandi va barcha seanslar yopildi. Agar bu siz bo‘lmasangiz, "
           "darhol administratorga murojaat qiling.", user.id)
    return {"ok": True}


# ------------------------------------------------------------------ sign-up with email confirmation

MAX_REGISTRATION_SENDS = 5
REGISTRATION_SENT = "Tasdiqlash kodi emailingizga yuborildi"


def _registration_code(reg_id: str, code: str) -> str:
    return keyed_hash(f"register:{reg_id}:{code}")


def _new_code() -> str:
    return f"{secrets.randbelow(1_000_000):06d}"


@router.get("/institutions")
def public_institutions(db: Session = Depends(get_db)):
    """Schools for the sign-up form: names only (public information, no
    counts or staff). Signing up with a school's exact name lets that school's
    administrator see and approve the request."""
    return [{"id": i.id, "name": i.name} for i in db.scalars(select(Institution).order_by(Institution.name))]


@router.post("/register", status_code=202)
def register(body: RegisterIn, request: Request, db: Session = Depends(get_db),
             ctx: AppContext = Depends(get_ctx)):
    """Step 1 of sign-up. Answers the same way whether or not the email is
    already used, so the form cannot be used to discover accounts; the owner
    of an existing account gets a warning email instead of a code."""
    s = ctx.settings
    ip = client_ip(request)
    _too_many(ctx, db, f"register-ip:{ip}", 5, 3600, ip, "registrations per IP")
    if not body.privacy_accepted:
        raise ApiError(422, "privacy_required", "Maxfiylik siyosatiga rozilik bering")
    email = body.email.lower()
    full_name = f"{body.last_name} {body.first_name}"
    problems = passwords.password_problems(body.password, email=email, full_name=full_name)
    if problems:
        raise ApiError(422, "weak_password", "; ".join(problems))

    now = utcnow()
    db.execute(delete(PendingRegistration).where(PendingRegistration.expires_at < now - timedelta(days=1)))
    existing = identity.find_by_email(db, email)
    school = _school_by_name(db, body.institution_name)
    if school is None:
        raise ApiError(422, "unknown_school", "Maktabingizni ro‘yxatdan tanlang")
    if existing is None and identity.phone_taken(db, body.phone):
        # Not a secret worth hiding: the person needs to know to sign in instead.
        raise ApiError(409, "phone_taken", "Bu telefon raqami bilan hisob allaqachon bor. Hisobingizga kiring yoki parolni tiklang")
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
        notify(db, ctx, existing.email, "Individ: ro‘yxatdan o‘tishga urinish",
                        "Kimdir ushbu email bilan Individ’da yangi hisob ochmoqchi bo‘ldi. Sizda allaqachon "
                        "hisob bor, shuning uchun yangi hisob ochilmadi.\nParolingizni unutgan bo‘lsangiz, "
                        "kirish sahifasidagi “Parolni unutdingizmi?” orqali tiklang. Agar bu siz "
                        "bo‘lmasangiz, hech narsa qilish shart emas.", existing.id)
    else:
        code = _new_code()
        reg.code_hash = _registration_code(reg.id, code)
        reg.data = json.dumps({
            "full_name": full_name,
            "phone": body.phone,
            "role": body.role.value,
            "institution_id": school.id,
            "password_hash": passwords.hash_password(body.password),
            "profile": {
                "first_name": body.first_name, "last_name": body.last_name,
                "specialization": body.specialization,
                "qualification_category": body.qualification_category,
                "experience_years": body.experience_years,
                "region": body.region, "district": body.district,
                "institution_name": body.institution_name,
                # When the person agreed to the privacy policy (proof of consent).
                "privacy_accepted_at": now.isoformat(),
            },
        })
        db.commit()
        try:
            ctx.mailer.send(email, _code_subject(code, "ro‘yxatdan o‘tish kodi"),
                            _code_mail(ctx, "ro‘yxatdan o‘tish", code))
        except MailError:
            db.delete(reg)
            db.commit()
            audit.record(db, "MAIL_FAILED", severity="alert", subject=audit.mask_login(email), ip=ip,
                         detail="register", webhook_url=s.alert_webhook_url)
            raise ApiError(503, "mail_failed", MAIL_FAILED) from None
        audit.record(db, "REGISTER_CODE_SENT", subject=audit.mask_login(email), ip=ip)
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
        try:
            ctx.mailer.send(reg.email, _code_subject(code, "ro‘yxatdan o‘tish kodi"),
                            _code_mail(ctx, "ro‘yxatdan o‘tish", code))
        except MailError:
            reg.last_sent_at = utcnow() - timedelta(seconds=s.code_resend_seconds)  # may retry at once
            db.commit()
            audit.record(db, "MAIL_FAILED", severity="alert", subject=audit.mask_login(reg.email), ip=ip,
                         detail="register resend", webhook_url=s.alert_webhook_url)
            raise ApiError(503, "mail_failed", MAIL_FAILED) from None
    return {"ok": True, "resend_after": s.code_resend_seconds, "message": REGISTRATION_SENT}


def _norm_school(x: str) -> str:
    return " ".join("".join(c for c in (x or "").lower() if c.isalnum() or c.isspace()).split())


def _school_by_name(db: Session, name: str) -> Institution | None:
    """The school picked from the public list at sign-up (matched by name)."""
    want = _norm_school(name)
    if not want:
        return None
    for inst in db.scalars(select(Institution)):
        if _norm_school(inst.name) == want:
            return inst
    return None


def _admin_of_named_school(db: Session, admin: User, school_name: str) -> bool:
    """A school administrator whose school is the one the sign-up named."""
    def norm(x: str) -> str:
        return " ".join("".join(c for c in (x or "").lower() if c.isalnum() or c.isspace()).split())
    inst = db.get(Institution, admin.institution_id) if admin.institution_id else None
    return inst is not None and bool(school_name) and norm(inst.name) == norm(school_name)


def _signup_notifications(db: Session, user: User, school: str, admins: list[User]) -> None:
    """The bell in the administrators' app: one notification each, readable only
    by that administrator (owner and recipient), like any personal item."""
    now = utcnow().isoformat()
    for admin in admins:
        rid = uuid.uuid4().hex
        db.add(Record(
            kind="notification", rid=rid, owner_id=admin.id, recipient_id=admin.id,
            institution_id=admin.institution_id,
            data=json.dumps({
                "recipientUserId": admin.id,
                "title": "Yangi ro‘yxatdan o‘tish",
                "body": f"{user.full_name}" + (f" ({school})" if school else "")
                        + " ro‘yxatdan o‘tdi va ishni boshladi.",
                "type": "SIGNUP",
                "relatedRecordId": user.id,
                "isRead": False,
                "createdAt": now,
            }, ensure_ascii=False),
        ))
    db.commit()


@router.post("/register/verify")
def register_verify(body: RegistrationVerifyIn, request: Request, response: Response,
                    db: Session = Depends(get_db), ctx: AppContext = Depends(get_ctx)):
    """Step 2: the emailed code creates the account in the school chosen at
    sign-up and signs the person in - the code has just proven the mailbox, so
    no second code is asked. Administrators are told; they can block the
    account if the person does not work there."""
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
    if identity.find_by_email(db, reg.email) is not None or identity.phone_taken(db, data["phone"]):  # taken meanwhile
        db.delete(reg)
        db.commit()
        raise ApiError(400, "invalid_code", "Kod noto‘g‘ri yoki muddati o‘tgan")
    school = db.get(Institution, data["institution_id"]) if data.get("institution_id") else None
    if school is None:  # sign-up started before schools were required
        school = _school_by_name(db, data["profile"].get("institution_name", ""))
    user = User(
        email=reg.email, full_name=data["full_name"], role=data["role"], phone=data["phone"],
        password_hash=data["password_hash"], must_change_password=False, is_active=True,
        pending_approval=False, institution_id=school.id if school else None,
        profile=json.dumps(data["profile"]),
    )
    db.add(user)
    db.delete(reg)
    db.commit()
    audit.record(db, "REGISTERED", user_id=user.id, subject=audit.mask_login(user.email), ip=ip)
    admins = [a for a in db.scalars(select(User).where(
        User.role.in_(("SUPER_ADMIN", "INSTITUTION_ADMIN")), User.is_active.is_(True)))
        if a.role == "SUPER_ADMIN" or _admin_of_named_school(db, a, data["profile"].get("institution_name", ""))]
    _signup_notifications(db, user, data["profile"].get("institution_name", ""), admins)
    for admin in admins:
        notify(db, ctx, admin.email, "Individ: yangi xodim qo‘shildi",
                        f"{user.full_name} ({data['profile'].get('institution_name', '')}) ro‘yxatdan o‘tdi va "
                        "tizimga kirdi. Agar u sizning muassasangizda ishlamasa, administrator panelidagi "
                        "“Foydalanuvchilar” bo‘limida hisobini bloklang.", admin.id)
    sess = sessions.issue(db, s, user, request, response, mfa_verified=True, ip=ip, factor="email",
                          remember=body.remember)
    audit.record(db, "LOGIN_OK", user_id=user.id, ip=ip, detail="sign-up email code")
    return _user_out(ctx, sess, user, message="Xush kelibsiz! Hisobingiz tayyor")
