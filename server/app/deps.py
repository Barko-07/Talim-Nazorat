"""Request dependencies: DB session, client IP, authentication and admin gate."""
from __future__ import annotations

import ipaddress
from collections.abc import Iterator
from dataclasses import dataclass

from fastapi import Depends, HTTPException, Request
from sqlalchemy.orm import Session

from .context import AppContext
from .crypto import constant_time_equals
from .models import AuthSession, Role, User
from .security import audit, sessions

SAFE_METHODS = {"GET", "HEAD", "OPTIONS"}


def get_ctx(request: Request) -> AppContext:
    return request.app.state.ctx


def get_db(ctx: AppContext = Depends(get_ctx)) -> Iterator[Session]:
    yield from ctx.db.session()


def client_ip(request: Request) -> str:
    """Real client IP. X-Real-IP is trusted only when the direct peer is our
    own reverse proxy (nginx), so clients cannot spoof it."""
    ctx: AppContext = request.app.state.ctx
    peer = request.client.host if request.client else ""
    if peer in ctx.settings.trusted_proxies:
        forwarded = request.headers.get("x-real-ip", "").strip()
        try:
            return str(ipaddress.ip_address(forwarded))
        except ValueError:
            pass
    return peer


class ApiError(HTTPException):
    def __init__(self, status: int, code: str, message: str, **extra):
        super().__init__(status_code=status, detail={"code": code, "message": message, **extra})


@dataclass
class Principal:
    session: AuthSession
    user: User
    ip: str


def _authenticate(request: Request, db: Session, allowed_states: set[str]) -> Principal:
    ctx: AppContext = request.app.state.ctx
    s = sessions.load(db, ctx.settings, request)
    if s is None:
        raise ApiError(401, "unauthenticated", "Tizimga qayta kiring")
    ip = client_ip(request)
    user = s.user
    if not user.is_active:
        sessions.revoke_all(db, user.id)
        raise ApiError(401, "unauthenticated", "Tizimga qayta kiring")
    state = sessions.session_state(ctx.settings, s)
    if state not in allowed_states:
        raise ApiError(403, state, "Avval xavfsizlik bosqichini yakunlang")
    if request.method not in SAFE_METHODS:
        sent = request.headers.get("x-csrf-token", "")
        if not sent or not constant_time_equals(sent, sessions.csrf_token(s)):
            audit.record(
                db, "CSRF_REJECTED", severity="warning", user_id=user.id, ip=ip,
                detail=f"{request.method} {request.url.path}",
                webhook_url=ctx.settings.alert_webhook_url,
            )
            raise ApiError(403, "csrf", "So‘rov rad etildi")
    return Principal(s, user, ip)


def require_user(request: Request, db: Session = Depends(get_db)) -> Principal:
    """Fully authenticated user (MFA done, password not expired)."""
    return _authenticate(request, db, {"ok"})


def require_partial(request: Request, db: Session = Depends(get_db)) -> Principal:
    """Logged in by password; may still need to finish MFA setup or change password."""
    return _authenticate(
        request, db, {"ok", "password_change_required", "mfa_setup_required"}
    )


ADMIN_ROLES = {Role.SUPER_ADMIN.value, Role.INSTITUTION_ADMIN.value}


def require_admin(
    request: Request,
    principal: Principal = Depends(require_user),
    db: Session = Depends(get_db),
) -> Principal:
    """An administrator: the system administrator (everything) or a school
    administrator (their own school only - routes narrow the scope). Both must
    have confirmed this login with the emailed code and, if configured, come
    from an allowed IP address."""
    ctx: AppContext = request.app.state.ctx
    u = principal.user
    allowlist = ctx.settings.admin_ip_allowlist
    ip_ok = not allowlist or _ip_allowed(principal.ip, allowlist)
    school_ok = u.role == Role.SUPER_ADMIN.value or u.institution_id is not None
    if u.role not in ADMIN_ROLES or not school_ok or not principal.session.mfa_verified or not ip_ok:
        audit.record(
            db, "ADMIN_ACCESS_DENIED", severity="warning", user_id=u.id, ip=principal.ip,
            detail=f"{request.method} {request.url.path}",
            webhook_url=ctx.settings.alert_webhook_url,
        )
        # 404, not 403: admin routes are not advertised to other users.
        raise ApiError(404, "not_found", "Topilmadi")
    return principal


def require_super(
    request: Request,
    principal: Principal = Depends(require_admin),
    db: Session = Depends(get_db),
) -> Principal:
    """System-wide actions (e.g. adding a school): the system administrator only."""
    if principal.user.role != Role.SUPER_ADMIN.value:
        audit.record(db, "ADMIN_ACCESS_DENIED", severity="warning", user_id=principal.user.id,
                     ip=principal.ip, detail=f"{request.method} {request.url.path}")
        raise ApiError(403, "forbidden", "Bu amalni faqat tizim administratori bajaradi")
    return principal


def _ip_allowed(ip: str, allowlist: list[str]) -> bool:
    try:
        addr = ipaddress.ip_address(ip)
    except ValueError:
        return False
    for entry in allowlist:
        try:
            if addr in ipaddress.ip_network(entry, strict=False):
                return True
        except ValueError:
            continue
    return False
