"""System administration. Every route requires require_admin: SUPER_ADMIN role,
two-factor verified session, optional IP allowlist. Others get 404."""
from __future__ import annotations

from datetime import timedelta

from fastapi import APIRouter, Depends, Query
from sqlalchemy import delete, func, select, update
from sqlalchemy.orm import Session

from ..context import AppContext
from ..deps import ApiError, Principal, get_ctx, get_db, require_admin
from ..models import AuditEvent, AuthSession, Institution, RecoveryCode, Role, User, utcnow
from ..schemas import ApproveIn, InstitutionIn, UserCreateIn, UserUpdateIn
from ..security import audit, passwords, sessions
from .auth import profile_of

router = APIRouter(prefix="/api/admin", tags=["admin"])


def _user_row(u: User) -> dict:
    return {
        "id": u.id, "email": u.email, "full_name": u.full_name, "role": u.role,
        "institution_id": u.institution_id, "is_active": u.is_active,
        "mfa_enabled": u.mfa_enabled, "locked": u.locked_now(utcnow()),
        "must_change_password": u.must_change_password,
        "pending_approval": u.pending_approval, "phone": u.phone, "profile": profile_of(u),
    }


def _get_user(db: Session, user_id: str) -> User:
    u = db.get(User, user_id)
    if u is None:
        raise ApiError(404, "not_found", "Foydalanuvchi topilmadi")
    return u


def _active_admins(db: Session) -> int:
    return db.scalar(
        select(func.count()).select_from(User).where(
            User.role == Role.SUPER_ADMIN.value, User.is_active.is_(True)
        )
    )


@router.get("/users")
def list_users(q: str = Query(default="", max_length=100), _: Principal = Depends(require_admin),
               db: Session = Depends(get_db)):
    stmt = select(User).order_by(User.full_name).limit(500)
    if q:
        # Bound parameter + escaped wildcards: input is data, never SQL.
        like = "%" + q.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_") + "%"
        stmt = stmt.where(User.full_name.ilike(like, escape="\\") | User.email.ilike(like, escape="\\"))
    return [_user_row(u) for u in db.scalars(stmt)]


@router.post("/users", status_code=201)
def create_user(body: UserCreateIn, p: Principal = Depends(require_admin),
                db: Session = Depends(get_db), ctx: AppContext = Depends(get_ctx)):
    email = body.email.lower()
    if db.scalar(select(User).where(User.email == email)):
        raise ApiError(409, "exists", "Bu email bilan hisob mavjud")
    if body.institution_id and db.get(Institution, body.institution_id) is None:
        raise ApiError(422, "bad_institution", "Muassasa topilmadi")
    temp = passwords.generate_temporary_password()
    u = User(email=email, full_name=body.full_name, role=body.role.value,
             institution_id=body.institution_id, phone=body.phone,
             password_hash=passwords.hash_password(temp), must_change_password=True)
    db.add(u)
    db.commit()
    # The temporary password goes only to the user's mailbox, never to the API response.
    ctx.mailer.send(email, "Individ: hisobingiz yaratildi",
                    f"Sizga Individ tizimida hisob ochildi.\nLogin: {email}\nVaqtinchalik parol: {temp}\n\n"
                    "Birinchi kirishda parolni o‘zgartirasiz. Parolni hech kimga bermang.")
    audit.record(db, "ADMIN_USER_CREATED", user_id=p.user.id, subject=u.id, ip=p.ip,
                 detail=f"role={u.role}")
    return _user_row(u)


@router.patch("/users/{user_id}")
def update_user(user_id: str, body: UserUpdateIn, p: Principal = Depends(require_admin),
                db: Session = Depends(get_db)):
    u = _get_user(db, user_id)
    if u.id == p.user.id and (body.role is not None or body.is_active is False):
        raise ApiError(409, "self_change", "O‘z rolingizni o‘zgartira yoki o‘zingizni bloklay olmaysiz")
    demoting = u.role == Role.SUPER_ADMIN.value and (
        (body.role is not None and body.role != Role.SUPER_ADMIN) or body.is_active is False
    )
    if demoting and _active_admins(db) <= 1:
        raise ApiError(409, "last_admin", "Oxirgi faol administratorni o‘zgartirib bo‘lmaydi")
    if body.full_name is not None:
        u.full_name = body.full_name
    if body.role is not None:
        u.role = body.role.value
    if body.is_active is not None:
        u.is_active = body.is_active
    moved = body.institution_id is not None and body.institution_id != u.institution_id
    if moved:
        if db.get(Institution, body.institution_id) is None:
            raise ApiError(422, "bad_institution", "Muassasa topilmadi")
        u.institution_id = body.institution_id
    db.commit()
    # Role, block and school changes apply at once: what a user may see depends on them.
    if body.is_active is False or body.role is not None or moved:
        sessions.revoke_all(db, u.id)  # changes apply immediately
    audit.record(db, "ADMIN_USER_UPDATED", user_id=p.user.id, subject=u.id, ip=p.ip,
                 detail=body.model_dump_json(exclude_none=True)[:400])
    return _user_row(u)


@router.post("/users/{user_id}/approve")
def approve_user(user_id: str, body: ApproveIn, p: Principal = Depends(require_admin),
                 db: Session = Depends(get_db), ctx: AppContext = Depends(get_ctx)):
    """Lets a self-registered account in, attached to the school the admin picks."""
    u = _get_user(db, user_id)
    if not u.pending_approval:
        raise ApiError(409, "not_pending", "Bu hisob tasdiq kutmayapti")
    if db.get(Institution, body.institution_id) is None:
        raise ApiError(422, "bad_institution", "Muassasa topilmadi")
    u.institution_id = body.institution_id
    u.pending_approval = False
    db.commit()
    audit.record(db, "ADMIN_USER_APPROVED", user_id=p.user.id, subject=u.id, ip=p.ip)
    ctx.mailer.send(u.email, "Individ: hisobingiz tasdiqlandi",
                    "Hisobingiz administrator tomonidan tasdiqlandi. Endi Individ’ga kirishingiz mumkin.")
    return _user_row(u)


@router.post("/users/{user_id}/reject")
def reject_user(user_id: str, p: Principal = Depends(require_admin), db: Session = Depends(get_db),
                ctx: AppContext = Depends(get_ctx)):
    """Deletes a sign-up that was never approved (it owns no data yet)."""
    u = _get_user(db, user_id)
    if not u.pending_approval:
        raise ApiError(409, "not_pending", "Faqat tasdiq kutayotgan hisobni rad etish mumkin")
    email = u.email
    db.delete(u)
    db.commit()
    audit.record(db, "ADMIN_USER_REJECTED", user_id=p.user.id, subject=audit.mask_login(email), ip=p.ip)
    ctx.mailer.send(email, "Individ: ro‘yxatdan o‘tish rad etildi",
                    "Ro‘yxatdan o‘tish so‘rovingiz administrator tomonidan rad etildi. Savollar bo‘lsa, "
                    "maktabingiz rahbariyatiga murojaat qiling.")
    return {"ok": True}


@router.post("/users/{user_id}/unlock")
def unlock_user(user_id: str, p: Principal = Depends(require_admin), db: Session = Depends(get_db)):
    u = _get_user(db, user_id)
    u.failed_logins = 0
    u.locked_until = None
    db.commit()
    audit.record(db, "ADMIN_USER_UNLOCKED", user_id=p.user.id, subject=u.id, ip=p.ip)
    return _user_row(u)


@router.post("/users/{user_id}/reset-mfa")
def reset_mfa(user_id: str, p: Principal = Depends(require_admin), db: Session = Depends(get_db)):
    u = _get_user(db, user_id)
    if u.id == p.user.id:
        raise ApiError(409, "self_change", "O‘z ikki bosqichli himoyangizni bu yerda o‘chira olmaysiz")
    u.mfa_enabled = False
    u.mfa_secret = None
    db.execute(delete(RecoveryCode).where(RecoveryCode.user_id == u.id))
    db.commit()
    sessions.revoke_all(db, u.id)
    audit.record(db, "ADMIN_MFA_RESET", severity="warning", user_id=p.user.id, subject=u.id, ip=p.ip)
    return _user_row(u)


@router.post("/users/{user_id}/revoke-sessions")
def revoke_sessions(user_id: str, p: Principal = Depends(require_admin), db: Session = Depends(get_db)):
    u = _get_user(db, user_id)
    sessions.revoke_all(db, u.id, except_id=p.session.id if u.id == p.user.id else None)
    audit.record(db, "ADMIN_SESSIONS_REVOKED", user_id=p.user.id, subject=u.id, ip=p.ip)
    return {"ok": True}


@router.get("/sessions")
def active_sessions(_: Principal = Depends(require_admin), db: Session = Depends(get_db)):
    since = utcnow() - timedelta(hours=24)
    rows = db.scalars(
        select(AuthSession).where(AuthSession.revoked.is_(False), AuthSession.last_seen_at >= since)
        .order_by(AuthSession.last_seen_at.desc()).limit(500)
    )
    return [{"id": s.id, "user_id": s.user_id, "ip": s.ip, "user_agent": s.user_agent,
             "mfa_verified": s.mfa_verified, "last_seen_at": s.last_seen_at.isoformat()} for s in rows]


@router.get("/institutions")
def list_institutions(_: Principal = Depends(require_admin), db: Session = Depends(get_db)):
    """Schools with how many active accounts each has (for approving sign-ups)."""
    counts = dict(
        db.execute(
            select(User.institution_id, func.count())
            .where(User.institution_id.is_not(None), User.pending_approval.is_(False))
            .group_by(User.institution_id)
        ).all()
    )
    rows = db.scalars(select(Institution).order_by(Institution.name)).all()
    return [{"id": i.id, "name": i.name, "region": i.region, "users": counts.get(i.id, 0)} for i in rows]


@router.post("/institutions", status_code=201)
def create_institution(body: InstitutionIn, p: Principal = Depends(require_admin),
                       db: Session = Depends(get_db)):
    if db.scalar(select(Institution).where(func.lower(Institution.name) == body.name.lower())):
        raise ApiError(409, "exists", "Bu nomdagi muassasa allaqachon bor")
    inst = Institution(name=body.name, region=body.region)
    db.add(inst)
    db.commit()
    audit.record(db, "ADMIN_INSTITUTION_CREATED", user_id=p.user.id, subject=inst.id, ip=p.ip)
    return {"id": inst.id, "name": inst.name, "region": inst.region}


@router.get("/audit")
def audit_log(severity: str | None = Query(default=None, pattern=r"^(info|warning|alert)$"),
              limit: int = Query(default=200, ge=1, le=1000),
              _: Principal = Depends(require_admin), db: Session = Depends(get_db)):
    stmt = select(AuditEvent).order_by(AuditEvent.id.desc()).limit(limit)
    if severity:
        stmt = stmt.where(AuditEvent.severity == severity)
    return [{"at": e.at.isoformat(), "action": e.action, "severity": e.severity, "user_id": e.user_id,
             "subject": e.subject, "ip": e.ip, "detail": e.detail} for e in db.scalars(stmt)]


@router.post("/users/{user_id}/force-password-change")
def force_password_change(user_id: str, p: Principal = Depends(require_admin),
                          db: Session = Depends(get_db)):
    u = _get_user(db, user_id)
    db.execute(update(User).where(User.id == u.id).values(must_change_password=True))
    db.commit()
    sessions.revoke_all(db, u.id)
    audit.record(db, "ADMIN_FORCED_PASSWORD_CHANGE", user_id=p.user.id, subject=u.id, ip=p.ip)
    return {"ok": True}
