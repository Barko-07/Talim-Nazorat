"""Server-side sessions in secure cookies, plus CSRF tokens bound to them."""
from __future__ import annotations

import secrets
from datetime import timedelta

from fastapi import Request, Response
from sqlalchemy import select, update
from sqlalchemy.orm import Session

from ..config import Settings
from ..crypto import keyed_hash
from ..models import AuthSession, User, _tz, utcnow

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


def csrf_token(session: AuthSession) -> str:
    return keyed_hash("csrf:" + session.id)


def session_state(settings: Settings, s: AuthSession) -> str:
    u = s.user
    if u.mfa_enabled and not s.mfa_verified:
        return "mfa_required"
    if u.must_change_password:
        return "password_change_required"
    if u.role in settings.mfa_required_roles and not u.mfa_enabled:
        return "mfa_setup_required"
    return "ok"
