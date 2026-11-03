"""Children's records. Every handler re-checks permissions on the server;
records from other schools are reported as 404 (their existence is hidden)."""
from __future__ import annotations

from fastapi import APIRouter, Depends, Path, Query
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from .. import access
from ..deps import ApiError, Principal, get_db, require_user
from ..models import Assessment, Observation, Student, User
from ..schemas import AssessmentIn, AssignIn, ObservationIn, StudentIn
from ..security import audit

router = APIRouter(prefix="/api/students", tags=["students"])

Id = Path(pattern=r"^[a-f0-9]{32}$")


def _student_out(u: User, s: Student) -> dict:
    sensitive = access.can_view_sensitive(u)
    return {
        "id": s.id, "full_name": s.full_name, "birth_date": s.birth_date.isoformat(),
        "grade": s.grade, "institution_id": s.institution_id, "archived": s.archived,
        "guardian_name": s.guardian_name,
        # Least privilege: medical data only for roles that need it.
        "diagnosis": s.diagnosis if sensitive else None,
        "guardian_phone": s.guardian_phone if sensitive else None,
        "specialist_ids": [sp.id for sp in s.specialists],
        "coordinator_id": s.coordinator_id,
    }


def _load(db: Session, p: Principal, student_id: str) -> Student:
    s = db.scalar(select(Student).options(selectinload(Student.specialists)).where(Student.id == student_id))
    if s is None or not access.can_view_student(p.user, s):
        if s is not None:
            audit.record(db, "ACCESS_DENIED", severity="warning", user_id=p.user.id, ip=p.ip,
                         subject=student_id, detail="view student")
        raise ApiError(404, "not_found", "Topilmadi")
    return s


def _deny(db: Session, p: Principal, what: str, subject: str = "") -> ApiError:
    audit.record(db, "ACCESS_DENIED", severity="warning", user_id=p.user.id, ip=p.ip,
                 subject=subject, detail=what)
    return ApiError(403, "forbidden", "Bu amal uchun ruxsatingiz yo‘q")


@router.get("")
def list_students(q: str = Query(default="", max_length=100), p: Principal = Depends(require_user),
                  db: Session = Depends(get_db)):
    stmt = select(Student).options(selectinload(Student.specialists)).where(Student.archived.is_(False))
    if not access.is_super(p.user):
        stmt = stmt.where(Student.institution_id == p.user.institution_id)
    if q:
        like = "%" + q.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_") + "%"
        stmt = stmt.where(Student.full_name.ilike(like, escape="\\"))
    rows = db.scalars(stmt.order_by(Student.full_name).limit(1000))
    return [_student_out(p.user, s) for s in rows if access.can_view_student(p.user, s)]


@router.post("", status_code=201)
def create_student(body: StudentIn, p: Principal = Depends(require_user), db: Session = Depends(get_db)):
    inst = body.institution_id if access.is_super(p.user) else p.user.institution_id
    if inst is None or not access.can_edit_student(p.user, inst):
        raise _deny(db, p, "create student")
    s = Student(institution_id=inst, **body.model_dump(exclude={"institution_id"}))
    db.add(s)
    db.commit()
    audit.record(db, "STUDENT_CREATED", user_id=p.user.id, subject=s.id, ip=p.ip)
    return _student_out(p.user, s)


@router.get("/{student_id}")
def get_student(student_id: str = Id, p: Principal = Depends(require_user), db: Session = Depends(get_db)):
    s = _load(db, p, student_id)
    audit.record(db, "STUDENT_VIEWED", user_id=p.user.id, subject=s.id, ip=p.ip)
    return _student_out(p.user, s)


@router.put("/{student_id}")
def update_student(body: StudentIn, student_id: str = Id, p: Principal = Depends(require_user),
                   db: Session = Depends(get_db)):
    s = _load(db, p, student_id)
    if not access.can_edit_student(p.user, s.institution_id):
        raise _deny(db, p, "edit student", s.id)
    for k, v in body.model_dump(exclude={"institution_id"}).items():
        setattr(s, k, v)
    db.commit()
    audit.record(db, "STUDENT_UPDATED", user_id=p.user.id, subject=s.id, ip=p.ip)
    return _student_out(p.user, s)


@router.post("/{student_id}/specialists")
def assign_specialist(body: AssignIn, student_id: str = Id, p: Principal = Depends(require_user),
                      db: Session = Depends(get_db)):
    s = _load(db, p, student_id)
    if not access.can_assign(p.user, s):
        raise _deny(db, p, "assign specialist", s.id)
    spec = db.get(User, body.user_id)
    if spec is None or not access.can_be_assigned(spec, s):
        raise ApiError(422, "bad_specialist", "Bu mutaxassisni biriktirib bo‘lmaydi")
    if spec not in s.specialists:
        s.specialists.append(spec)
        db.commit()
    audit.record(db, "SPECIALIST_ASSIGNED", user_id=p.user.id, subject=s.id, ip=p.ip, detail=spec.id)
    return _student_out(p.user, s)


# ------------------------------------------------------------------ assessments

def _assessment_out(a: Assessment) -> dict:
    return {
        "id": a.id, "student_id": a.student_id, "specialist_id": a.specialist_id, "title": a.title,
        "category": a.category, "assessment_date": a.assessment_date.isoformat(),
        "total_score": a.total_score, "max_score": a.max_score, "status": a.status, "notes": a.notes,
    }


@router.get("/{student_id}/assessments")
def list_assessments(student_id: str = Id, p: Principal = Depends(require_user), db: Session = Depends(get_db)):
    s = _load(db, p, student_id)
    rows = db.scalars(select(Assessment).where(Assessment.student_id == s.id)
                      .order_by(Assessment.assessment_date.desc()))
    return [_assessment_out(a) for a in rows]


@router.post("/{student_id}/assessments", status_code=201)
def create_assessment(body: AssessmentIn, student_id: str = Id, p: Principal = Depends(require_user),
                      db: Session = Depends(get_db)):
    s = _load(db, p, student_id)
    if not access.can_create_assessment(p.user, s):
        raise _deny(db, p, "create assessment", s.id)
    if body.total_score > body.max_score:
        raise ApiError(422, "bad_score", "Ball maksimaldan oshmasin")
    a = Assessment(student_id=s.id, specialist_id=p.user.id, **body.model_dump())
    db.add(a)
    db.commit()
    audit.record(db, "ASSESSMENT_CREATED", user_id=p.user.id, subject=a.id, ip=p.ip)
    return _assessment_out(a)


@router.delete("/{student_id}/assessments/{assessment_id}", status_code=204)
def delete_assessment(student_id: str = Id, assessment_id: str = Id, p: Principal = Depends(require_user),
                      db: Session = Depends(get_db)):
    s = _load(db, p, student_id)
    a = db.scalar(select(Assessment).where(Assessment.id == assessment_id, Assessment.student_id == s.id))
    if a is None:
        raise ApiError(404, "not_found", "Topilmadi")
    if not access.can_modify_assessment(p.user, a):
        raise _deny(db, p, "delete assessment", a.id)
    db.delete(a)
    db.commit()
    audit.record(db, "ASSESSMENT_DELETED", severity="warning", user_id=p.user.id, subject=assessment_id, ip=p.ip)


# ------------------------------------------------------------------ observations

@router.get("/{student_id}/observations")
def list_observations(student_id: str = Id, p: Principal = Depends(require_user), db: Session = Depends(get_db)):
    s = _load(db, p, student_id)
    rows = db.scalars(select(Observation).where(Observation.student_id == s.id)
                      .order_by(Observation.created_at.desc()))
    out = []
    for o in rows:
        if o.confidential and not access.can_view_confidential_observation(p.user, o.psychologist_id):
            continue
        out.append({"id": o.id, "psychologist_id": o.psychologist_id, "confidential": o.confidential,
                    "text": o.text, "created_at": o.created_at.isoformat()})
    return out


@router.post("/{student_id}/observations", status_code=201)
def create_observation(body: ObservationIn, student_id: str = Id, p: Principal = Depends(require_user),
                       db: Session = Depends(get_db)):
    s = _load(db, p, student_id)
    if not access.can_write_observation(p.user, s):
        raise _deny(db, p, "write observation", s.id)
    o = Observation(student_id=s.id, psychologist_id=p.user.id, text=body.text, confidential=body.confidential)
    db.add(o)
    db.commit()
    audit.record(db, "OBSERVATION_CREATED", user_id=p.user.id, subject=o.id, ip=p.ip)
    return {"id": o.id, "confidential": o.confidential}
