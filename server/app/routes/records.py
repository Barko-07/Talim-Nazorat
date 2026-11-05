"""Work data: children and everything recorded about them.

GET  /api/records        everything the signed-in user may see, by kind
POST /api/records/batch  add / change / delete items in one transaction
GET  /api/directory      names and roles of the people the user works with

Each item is stored as encrypted JSON. The server fixes the fields that decide
access (school, child, author, assignments) itself, so the app cannot widen
who sees what. Every change is written to the history administrators read.
"""
from __future__ import annotations

import json
from dataclasses import dataclass, field

from fastapi import APIRouter, Depends
from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from .. import access
from ..deps import ApiError, Principal, get_db, require_user
from ..models import Institution, Record, RecordChange, StudentAccess, User, utcnow
from ..schemas import BatchIn
from ..security import audit

router = APIRouter(prefix="/api", tags=["records"])

MAX_ITEM_BYTES = 200_000
# Fields of a child's card that only an administrator may change.
PROTECTED_STUDENT_FIELDS = ("institutionId", "assignedSpecialistIds", "coordinatorId")


def _denied(db: Session, p: Principal, what: str, subject: str = "", index: int | None = None) -> ApiError:
    audit.record(db, "ACCESS_DENIED", severity="warning", user_id=p.user.id, ip=p.ip,
                 subject=subject[:120], detail=what)
    extra = {} if index is None else {"index": index}
    return ApiError(403, "forbidden", "Bu amal uchun ruxsatingiz yo‘q", **extra)


def _not_found(index: int | None = None) -> ApiError:
    # Records the user may not see are reported exactly like missing ones.
    extra = {} if index is None else {"index": index}
    return ApiError(404, "not_found", "Topilmadi", **extra)


# ------------------------------------------------------------------ reading


@dataclass
class _View:
    """What one user may see, computed once per request."""

    user: User
    students: dict[str, Record] = field(default_factory=dict)
    assigned: dict[str, set[str]] = field(default_factory=dict)

    def student_visible(self, student_id: str | None) -> bool:
        s = self.students.get(student_id or "")
        return s is not None and access.can_see_student(self.user, s, self.assigned.get(s.rid, set()))


def _assignments(db: Session, student_ids: list[str]) -> dict[str, set[str]]:
    out: dict[str, set[str]] = {}
    if not student_ids:
        return out
    for i in range(0, len(student_ids), 500):
        for sa in db.scalars(select(StudentAccess).where(StudentAccess.student_id.in_(student_ids[i:i + 500]))):
            out.setdefault(sa.student_id, set()).add(sa.user_id)
    return out


def _load_students(db: Session, u: User, ids: list[str] | None = None) -> _View:
    """The children whose cards matter for this request (all in scope, or `ids`)."""
    stmt = select(Record).where(Record.kind == access.STUDENT)
    if ids is not None:
        stmt = stmt.where(Record.rid.in_(ids or [""]))
    elif access.is_super(u):
        pass
    elif access.is_admin(u):
        stmt = stmt.where(Record.institution_id == u.institution_id)
    else:
        mine = select(StudentAccess.student_id).where(StudentAccess.user_id == u.id)
        stmt = stmt.where(Record.institution_id == u.institution_id, Record.rid.in_(mine))
    students = {s.rid: s for s in db.scalars(stmt)}
    return _View(u, students, _assignments(db, list(students)))


def _student_out(rec: Record, assigned: set[str], coordinator: str | None) -> dict:
    data = json.loads(rec.data)
    data["id"] = rec.rid
    data["institutionId"] = rec.institution_id
    data["assignedSpecialistIds"] = sorted(assigned - ({coordinator} if coordinator else set()))
    data["coordinatorId"] = coordinator
    return data


def _coordinator(db: Session, student_id: str) -> str | None:
    return db.scalar(select(StudentAccess.user_id).where(
        StudentAccess.student_id == student_id, StudentAccess.via == "coordinator"))


def _out(db: Session, rec: Record, view: _View) -> dict:
    if rec.kind == access.STUDENT:
        return _student_out(rec, view.assigned.get(rec.rid, set()), _coordinator(db, rec.rid))
    data = json.loads(rec.data)
    data["id"] = rec.rid
    return data


@router.get("/records")
def list_records(p: Principal = Depends(require_user), db: Session = Depends(get_db)):
    u = p.user
    view = _load_students(db, u)
    visible_students = [sid for sid in view.students if view.student_visible(sid)]

    conds = [Record.kind.in_(access.PERSONAL_KINDS) & or_(Record.owner_id == u.id, Record.recipient_id == u.id)]
    if visible_students:
        for i in range(0, len(visible_students), 500):
            conds.append(Record.student_id.in_(visible_students[i:i + 500]) & Record.kind.in_(access.CHILD_KINDS))
    if access.is_super(u):
        conds.append(Record.kind.in_(access.SCHOOL_KINDS | access.PERSONAL_KINDS))
    else:
        conds.append(Record.kind.in_(access.SCHOOL_KINDS) & (Record.institution_id == u.institution_id))
        if access.is_admin(u):
            conds.append(Record.kind.in_(access.PERSONAL_KINDS) & (Record.institution_id == u.institution_id))

    items: dict[str, list[dict]] = {k: [] for k in access.ALL_KINDS}
    coordinators = {
        sa.student_id: sa.user_id
        for sa in db.scalars(select(StudentAccess).where(StudentAccess.via == "coordinator",
                                                         StudentAccess.student_id.in_(visible_students or [""])))
    }
    for sid in visible_students:
        s = view.students[sid]
        items[access.STUDENT].append(_student_out(s, view.assigned.get(sid, set()), coordinators.get(sid)))
    count = len(visible_students)
    for rec in db.scalars(select(Record).where(Record.deleted.is_(False), or_(*conds))):
        if access.can_see(u, rec, view.student_visible(rec.student_id)):
            data = json.loads(rec.data)
            data["id"] = rec.rid
            items[rec.kind].append(data)
            count += 1
    # Reading the whole set is logged too: who pulled how much, and when.
    audit.record(db, "RECORDS_READ", user_id=u.id, ip=p.ip, detail=f"{count} items")
    return {"items": items, "count": count}


# ------------------------------------------------------------------ writing


def _clean_data(data: dict, index: int) -> dict:
    raw = json.dumps(data, ensure_ascii=False)
    if len(raw.encode()) > MAX_ITEM_BYTES:
        raise ApiError(413, "too_large", "Yozuv hajmi juda katta", index=index)
    return json.loads(raw)


def _school_user(db: Session, user_id: str, institution_id: str | None) -> User | None:
    other = db.get(User, user_id)
    if other is None or not other.is_active or other.pending_approval:
        return None
    if other.institution_id != institution_id:
        return None
    return other


def _set_assignments(db: Session, student_id: str, assigned: set[str], coordinator: str | None) -> None:
    for sa in db.scalars(select(StudentAccess).where(StudentAccess.student_id == student_id)):
        db.delete(sa)
    db.flush()
    for uid in assigned:
        if uid != coordinator:
            db.add(StudentAccess(student_id=student_id, user_id=uid, via="assigned"))
    if coordinator:
        db.add(StudentAccess(student_id=student_id, user_id=coordinator, via="coordinator"))


def _history(db: Session, p: Principal, rec: Record, action: str, before: dict | None, after: dict | None) -> None:
    if action == "update":
        keys = sorted(k for k in set(before or {}) | set(after or {})
                      if (before or {}).get(k) != (after or {}).get(k))
        if not keys:
            return
        before = {k: (before or {}).get(k) for k in keys}
        after = {k: (after or {}).get(k) for k in keys}
    else:
        keys = sorted((after or before or {}).keys())
    db.add(RecordChange(
        user_id=p.user.id, kind=rec.kind, rid=rec.rid, student_id=rec.student_id,
        institution_id=rec.institution_id, action=action, fields=",".join(keys)[:1000],
        before=None if before is None else json.dumps(before, ensure_ascii=False),
        after=None if after is None else json.dumps(after, ensure_ascii=False),
    ))


def _put_student(db: Session, p: Principal, rec: Record | None, rid: str, data: dict, index: int) -> Record:
    u = p.user
    if rec is None:
        if not access.can_write(u):
            raise _denied(db, p, "create student", rid, index)
        inst = u.institution_id
        if access.is_super(u):
            inst = data.get("institutionId") or None
            if inst is None or db.get(Institution, inst) is None:
                raise ApiError(422, "bad_institution", "Muassasa topilmadi", index=index)
        if inst is None:
            raise _denied(db, p, "create student without school", rid, index)
        rec = Record(kind=access.STUDENT, rid=rid, institution_id=inst, owner_id=u.id, data="{}")
        db.add(rec)
        assigned, coordinator = {u.id}, None
        if access.admin_for(u, inst):
            assigned = set(data.get("assignedSpecialistIds") or [])
            coordinator = data.get("coordinatorId") or None
        before = None
    else:
        before = json.loads(rec.data)
        assigned = {sa.user_id for sa in db.scalars(select(StudentAccess).where(
            StudentAccess.student_id == rid, StudentAccess.via == "assigned"))}
        coordinator = _coordinator(db, rid)
        if not access.admin_for(u, rec.institution_id):
            # Only an administrator decides who works with a child: an attempt
            # to change it is refused openly, not silently ignored.
            wants = set(data.get("assignedSpecialistIds") or [])
            wants_coord = data.get("coordinatorId") or None
            if ("assignedSpecialistIds" in data and wants != assigned) or (
                    "coordinatorId" in data and wants_coord != coordinator):
                raise _denied(db, p, "change assignments", rid, index)
        if access.admin_for(u, rec.institution_id):
            assigned = set(data.get("assignedSpecialistIds") or [])
            coordinator = data.get("coordinatorId") or None
            new_inst = data.get("institutionId") or rec.institution_id
            if new_inst != rec.institution_id:
                if not access.is_super(u) or db.get(Institution, new_inst) is None:
                    raise ApiError(422, "bad_institution", "Muassasa topilmadi", index=index)
                rec.institution_id = new_inst
    for uid in assigned | ({coordinator} if coordinator else set()):
        if _school_user(db, uid, rec.institution_id) is None:
            raise ApiError(422, "bad_specialist", "Bu xodimni biriktirib bo‘lmaydi", index=index)
    _set_assignments(db, rid, assigned, coordinator)
    for k in PROTECTED_STUDENT_FIELDS:
        data.pop(k, None)
    data.pop("id", None)
    rec.data = json.dumps(data, ensure_ascii=False)
    _history(db, p, rec, "create" if before is None else "update", before, data)
    return rec


def _put_other(db: Session, p: Principal, rec: Record | None, kind: str, rid: str, data: dict,
               view: _View, index: int) -> Record:
    u = p.user
    if rec is not None:
        if not access.can_see(u, rec, view.student_visible(rec.student_id)):
            raise _not_found(index)
        if not access.can_change(u, rec):
            raise _denied(db, p, f"change {kind}", rid, index)
        before = json.loads(rec.data)
        if kind in access.CHILD_KINDS:
            data["studentId"] = rec.student_id  # an item never moves to another child
        if kind in access.PERSONAL_KINDS:
            data["recipientUserId"] = rec.recipient_id
    else:
        if not access.can_write(u):
            raise _denied(db, p, f"create {kind}", rid, index)
        before = None
        rec = Record(kind=kind, rid=rid, owner_id=u.id, data="{}")
        if kind in access.CHILD_KINDS:
            sid = str(data.get("studentId") or "")
            if not view.student_visible(sid):
                raise _not_found(index)
            if kind == "observation" and not access.can_write_observation(u):
                raise _denied(db, p, "create observation", rid, index)
            rec.student_id = sid
            rec.institution_id = view.students[sid].institution_id
        elif kind in access.PERSONAL_KINDS:
            to = str(data.get("recipientUserId") or "")
            target = db.get(User, to)
            ok = target is not None and target.is_active and (
                to == u.id or access.is_super(u) or target.institution_id == u.institution_id)
            if not ok:
                raise _not_found(index)
            rec.recipient_id = to
            rec.institution_id = target.institution_id
        else:  # school-wide
            rec.institution_id = u.institution_id
        db.add(rec)
    if kind == "observation":
        rec.confidential = bool(data.get("isConfidential", True))
    data.pop("id", None)
    rec.data = json.dumps(data, ensure_ascii=False)
    _history(db, p, rec, "create" if before is None else "update", before, data)
    return rec


@router.post("/records/batch")
def batch(body: BatchIn, p: Principal = Depends(require_user), db: Session = Depends(get_db)):
    """All operations succeed together or none is applied."""
    u = p.user
    # Children named anywhere in the batch, loaded once with their teams.
    wanted = {op.id for op in body.ops if op.kind == access.STUDENT}
    wanted |= {str((op.data or {}).get("studentId") or "") for op in body.ops if op.kind in access.CHILD_KINDS}
    existing = {}
    for op in body.ops:
        rec = db.get(Record, (op.kind, op.id))
        if rec is not None:
            existing[(op.kind, op.id)] = rec
            if rec.student_id:
                wanted.add(rec.student_id)
    view = _load_students(db, u, sorted(wanted - {""}))

    out: list[dict] = []
    counts = {"create": 0, "update": 0, "delete": 0}
    try:
        for i, op in enumerate(body.ops):
            rec = existing.get((op.kind, op.id))
            if rec is not None and rec.deleted:
                raise _not_found(i)
            if op.kind == access.STUDENT and rec is not None and not view.student_visible(rec.rid):
                raise _not_found(i)
            if op.op == "delete":
                if rec is None:
                    continue  # already gone
                if op.kind != access.STUDENT and not access.can_see(u, rec, view.student_visible(rec.student_id)):
                    raise _not_found(i)
                if not access.can_delete(u, rec):
                    raise _denied(db, p, f"delete {op.kind}", op.id, i)
                rec.deleted = True
                rec.updated_at, rec.updated_by, rec.version = utcnow(), u.id, rec.version + 1
                _history(db, p, rec, "delete", json.loads(rec.data), None)
                counts["delete"] += 1
                continue
            data = _clean_data(op.data or {}, i)
            is_new = rec is None
            if op.kind == access.STUDENT:
                rec = _put_student(db, p, rec, op.id, data, i)
                db.flush()
                view.students[rec.rid] = rec
                view.assigned[rec.rid] = {sa.user_id for sa in db.scalars(
                    select(StudentAccess).where(StudentAccess.student_id == rec.rid))}
            else:
                rec = _put_other(db, p, rec, op.kind, op.id, data, view, i)
            counts["create" if is_new else "update"] += 1
            if not is_new:
                rec.version += 1
            rec.updated_at, rec.updated_by = utcnow(), u.id
            existing[(op.kind, op.id)] = rec
            db.flush()
            out.append({"kind": op.kind, "data": _out(db, rec, view)})
        db.commit()
    except Exception:
        db.rollback()
        raise
    audit.record(db, "RECORDS_CHANGED", user_id=u.id, ip=p.ip,
                 detail=", ".join(f"{k}={v}" for k, v in counts.items()))
    return {"items": out}


# ------------------------------------------------------------------ people


@router.get("/directory")
def directory(p: Principal = Depends(require_user), db: Session = Depends(get_db)):
    """Names and roles only - no email, phone or profile. Administrators get
    everyone in their scope; others their own school's active staff (needed to
    address a referral and to show who wrote what)."""
    u = p.user
    stmt = select(User).where(User.is_active.is_(True), User.pending_approval.is_(False))
    if not access.is_super(u):
        if u.institution_id is None:
            stmt = stmt.where(User.id == u.id)
        else:
            stmt = stmt.where(User.institution_id == u.institution_id)
    return [{"id": x.id, "full_name": x.full_name, "role": x.role, "institution_id": x.institution_id}
            for x in db.scalars(stmt.order_by(User.full_name).limit(5000))]
