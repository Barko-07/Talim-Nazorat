"""Server-side sessions in secure cookies, plus CSRF tokens bound to them."""
from __future__ import annotations

import secrets
from datetime import timedelta

from fastapi import Request, Response
from sqlalchemy import select, update
from sqlalchemy.orm import Session

from ..config import Settings
from ..crypto import keyed_hash
from ..models import AuthSession, TrustedDevice, User, _tz, utcnow

TOUCH_EVERY = timedelta(seconds=60)


def cookie_name(settings: Settings) -> str:
    # The __Host- prefix makes browsers refuse the cookie unless it is Secure,
    # has Path=/ and no Domain - it cannot be set or overridden by a subdomain.
    return "__Host-individ_session" if settings.cookie_secure else "individ_session"


def issue(
    db: Session,
    settings: Settings,
    user: User,
    request: Request,
    response: Response,
    *,
    mfa_verified: bool,
    ip: str,
    factor: str = "",
) -> AuthSession:
    """Creates a fresh session (new random token) and sets the cookie.
    Called on login and on every privilege change, so a token known before
    login (session fixation) is never upgraded."""
    old = request.cookies.get(cookie_name(settings))
    if old:
        db.execute(
            update(AuthSession).where(AuthSession.token_hash == keyed_hash(old)).values(revoked=True)
        )
    token = secrets.token_urlsafe(32)
    s = AuthSession(
        token_hash=keyed_hash(token),
        user_id=user.id,
        mfa_verified=mfa_verified,
        factor=factor if mfa_verified else "",
        ip=ip,
        user_agent=(request.headers.get("user-agent") or "")[:300],
    )
    db.add(s)
    db.commit()
    response.set_cookie(
        cookie_name(settings),
        token,
        max_age=settings.session_absolute_hours * 3600,
        path="/",
        secure=settings.cookie_secure,
        httponly=True,  # JavaScript (and so XSS) cannot read it
        samesite="strict",  # never sent on cross-site requests
    )
    return s


def clear_cookie(settings: Settings, response: Response) -> None:
    response.delete_cookie(
        cookie_name(settings), path="/", secure=settings.cookie_secure, httponly=True, samesite="strict"
    )


def load(db: Session, settings: Settings, request: Request) -> AuthSession | None:
    token = request.cookies.get(cookie_name(settings))
    if not token or len(token) > 100:
        return None
    s = db.scalar(select(AuthSession).where(AuthSession.token_hash == keyed_hash(token)))
    if s is None or s.revoked:
        return None
    now = utcnow()
    idle_limit = _tz(s.last_seen_at) + timedelta(minutes=settings.session_idle_minutes)
    abs_limit = _tz(s.created_at) + timedelta(hours=settings.session_absolute_hours)
    if now > idle_limit or now > abs_limit:
        s.revoked = True
        db.commit()
        return None
    if now - _tz(s.last_seen_at) > TOUCH_EVERY:
        s.last_seen_at = now
        db.commit()
    return s


def revoke_all(db: Session, user_id: str, *, except_id: str | None = None) -> None:
    q = update(AuthSession).where(AuthSession.user_id == user_id, AuthSession.revoked.is_(False))
    if except_id:
        q = q.where(AuthSession.id != except_id)
    db.execute(q.values(revoked=True))
    db.commit()


# ------------------------------------------------------------------ remembered devices

def device_cookie_name(settings: Settings) -> str:
    return "__Host-individ_device" if settings.cookie_secure else "individ_device"


def may_remember_device(settings: Settings, user: User) -> bool:
    # Admin accounts always prove the second factor: they control everything.
    return user.role not in settings.mfa_required_roles and not user.mfa_enabled


def remember_device(db: Session, settings: Settings, user: User, request: Request,
                    response: Response) -> None:
    token = secrets.token_urlsafe(32)
    db.add(TrustedDevice(
        user_id=user.id,
        token_hash=keyed_hash("device:" + token),
        expires_at=utcnow() + timedelta(days=settings.trusted_device_days),
        user_agent=(request.headers.get("user-agent") or "")[:300],
    ))
    db.commit()
    response.set_cookie(
        device_cookie_name(settings), token,
        max_age=settings.trusted_device_days * 86400, path="/",
        secure=settings.cookie_secure, httponly=True, samesite="strict",
    )


def trusted_device(db: Session, settings: Settings, user: User, request: Request) -> bool:
    """True when this browser/phone was remembered by this user, the promise has
    not expired, and the password has not changed since."""
    if not may_remember_device(settings, user):
        return False
    token = request.cookies.get(device_cookie_name(settings))
    if not token or len(token) > 100:
        return False
    d = db.scalar(select(TrustedDevice).where(TrustedDevice.token_hash == keyed_hash("device:" + token)))
    return (
        d is not None
        and not d.revoked
        and d.user_id == user.id
        and _tz(d.expires_at) > utcnow()
        and _tz(d.created_at) >= _tz(user.password_changed_at)
    )


def forget_devices(db: Session, user_id: str) -> None:
    db.execute(update(TrustedDevice).where(TrustedDevice.user_id == user_id).values(revoked=True))
    db.commit()


def csrf_token(session: AuthSession) -> str:
    return keyed_hash("csrf:" + session.id)


def session_state(settings: Settings, s: AuthSession) -> str:
    """Every login needs a second factor: the authenticator app once it is set
    up, otherwise a code emailed to the account. Admin roles without 2FA yet
    prove their email first and then must set up the authenticator."""
    u = s.user
    if not s.mfa_verified:
        return "mfa_required" if u.mfa_enabled else "email_code_required"
    if u.must_change_password:
        return "password_change_required"
    if u.role in settings.mfa_required_roles and not u.mfa_enabled:
        return "mfa_setup_required"
    return "ok"
