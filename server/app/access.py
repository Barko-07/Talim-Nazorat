"""Server-side permission rules - a port of the Flutter AccessControlService.
The server is the authority: the app hiding a button is only convenience."""
from __future__ import annotations

from .models import Assessment, Role, Student, User

R = Role

SCHOOL_WIDE = {R.INSTITUTION_ADMIN.value, R.COORDINATOR.value, R.REVIEWER.value}
CHILD_FACING = {
    R.PSYCHOLOGIST.value, R.SPEECH_THERAPIST.value, R.SPECIAL_EDUCATION.value,
    R.SPECIAL_ED_TEACHER.value, R.TEACHER.value,
}
SENSITIVE_MEDICAL = {
    R.SUPER_ADMIN.value, R.INSTITUTION_ADMIN.value, R.PSYCHOLOGIST.value,
    R.SPEECH_THERAPIST.value, R.SPECIAL_EDUCATION.value, R.COORDINATOR.value,
}
ASSIGNERS = {R.INSTITUTION_ADMIN.value, R.COORDINATOR.value}


def is_super(u: User) -> bool:
    return u.is_active and u.role == R.SUPER_ADMIN.value


def same_school(u: User, institution_id: str | None) -> bool:
    return u.institution_id is not None and u.institution_id == institution_id


def is_assigned(u: User, s: Student) -> bool:
    return s.coordinator_id == u.id or any(sp.id == u.id for sp in s.specialists)


def can_view_student(u: User, s: Student) -> bool:
    if not u.is_active:
        return False
    if is_super(u):
        return True
    if not same_school(u, s.institution_id):
        return False
    if u.role in SCHOOL_WIDE:
        return True
    if u.role in CHILD_FACING:
        return is_assigned(u, s)
    return False


def can_view_sensitive(u: User) -> bool:
    return u.is_active and u.role in SENSITIVE_MEDICAL


def can_edit_student(u: User, institution_id: str | None) -> bool:
    if is_super(u):
        return True
    return (
        u.is_active
        and u.role in {R.INSTITUTION_ADMIN.value, R.COORDINATOR.value}
        and same_school(u, institution_id)
    )


def can_assign(u: User, s: Student) -> bool:
    if is_super(u):
        return True
    return u.is_active and u.role in ASSIGNERS and same_school(u, s.institution_id)


def can_be_assigned(specialist: User, s: Student) -> bool:
    return (
        specialist.is_active
        and specialist.role in CHILD_FACING
        and same_school(specialist, s.institution_id)
    )


def can_create_assessment(u: User, s: Student) -> bool:
    if not u.is_active or u.role in {R.REVIEWER.value, R.PARENT.value}:
        return False
    return is_super(u) or can_view_student(u, s)


def can_modify_assessment(u: User, a: Assessment) -> bool:
    if is_super(u):
        return True
    return u.is_active and (a.specialist_id == u.id or u.role == R.INSTITUTION_ADMIN.value)


def can_write_observation(u: User, s: Student) -> bool:
    if is_super(u):
        return True
    return u.is_active and u.role == R.PSYCHOLOGIST.value and can_view_student(u, s)


def can_view_confidential_observation(u: User, psychologist_id: str) -> bool:
    if not u.is_active:
        return False
    return u.id == psychologist_id or u.role in {R.PSYCHOLOGIST.value, R.SUPER_ADMIN.value}
