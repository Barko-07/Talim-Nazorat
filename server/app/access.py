"""Who may see and change what. The server is the authority: the app hiding a
button is only convenience.

The rule: specialists add children themselves and form each child's team,
linking colleagues from their school. Only the team sees the child and what is
recorded about them - not other colleagues, nothing across schools.
Administrators run the system: they see their scope for oversight (and every
change in the history) but are not on teams.
"""
from __future__ import annotations

from .models import Record, Role, User

R = Role

# Kinds of work data the app stores. Each one is tied to a child, to one
# person (notifications), or shared inside a school (question bank etc.).
STUDENT = "student"
CHILD_KINDS = {
    "assessment", "session", "iep", "referral", "observation", "assessment_plan",
    "subject_level", "measurement", "subject_task", "achievement", "conference",
    "sound_entry",
}
PERSONAL_KINDS = {"notification"}
SCHOOL_KINDS = {"question", "curriculum", "custom_metric"}
ALL_KINDS = {STUDENT} | CHILD_KINDS | PERSONAL_KINDS | SCHOOL_KINDS

# People who work with children and can be on a child's team. Administrators
# run the system and are not team members.
TEAM_ROLES = {
    R.PSYCHOLOGIST.value, R.SPEECH_THERAPIST.value, R.SPECIAL_EDUCATION.value,
    R.SPECIAL_ED_TEACHER.value, R.TEACHER.value, R.COORDINATOR.value, R.REVIEWER.value,
}

# Read-only roles: they may look at what they are assigned to, never write.
READ_ONLY = {R.REVIEWER.value, R.PARENT.value}


def is_super(u: User) -> bool:
    return u.is_active and u.role == R.SUPER_ADMIN.value


def is_admin(u: User) -> bool:
    return u.is_active and u.role in {R.SUPER_ADMIN.value, R.INSTITUTION_ADMIN.value}


def same_school(u: User, institution_id: str | None) -> bool:
    return u.institution_id is not None and u.institution_id == institution_id


def admin_for(u: User, institution_id: str | None) -> bool:
    """Administrator whose scope includes this school."""
    if is_super(u):
        return True
    return u.is_active and u.role == R.INSTITUTION_ADMIN.value and same_school(u, institution_id)


def can_write(u: User) -> bool:
    return u.is_active and u.role not in READ_ONLY


def can_see_student(u: User, student: Record, assigned: set[str]) -> bool:
    if not u.is_active or student.deleted:
        return False
    if admin_for(u, student.institution_id):
        return True
    return same_school(u, student.institution_id) and u.id in assigned


def can_see(u: User, rec: Record, student_visible: bool) -> bool:
    """Any record other than a child's own card. `student_visible` is the
    answer of can_see_student for the child the record belongs to."""
    if not u.is_active or rec.deleted:
        return False
    if rec.kind in CHILD_KINDS:
        if not student_visible:
            return False
        # A psychologist's confidential note: its author and administrators only.
        return not rec.confidential or rec.owner_id == u.id or admin_for(u, rec.institution_id)
    if rec.kind in PERSONAL_KINDS:
        return rec.owner_id == u.id or rec.recipient_id == u.id or admin_for(u, rec.institution_id)
    if rec.kind in SCHOOL_KINDS:
        return is_super(u) or same_school(u, rec.institution_id)
    return False


def can_change(u: User, rec: Record) -> bool:
    """Edit or delete a record the user can already see. Everyone on a child's
    team edits the child's work (each edit is kept in the history); deletes and
    confidential notes stay with the author and administrators."""
    if admin_for(u, rec.institution_id):
        return True
    if not can_write(u):
        return False
    if rec.kind in PERSONAL_KINDS:
        return rec.owner_id == u.id or rec.recipient_id == u.id
    if rec.kind in SCHOOL_KINDS or rec.confidential:
        return rec.owner_id == u.id
    return True


def can_delete(u: User, rec: Record) -> bool:
    if rec.kind == STUDENT:
        # The person who added the child, or an administrator.
        return admin_for(u, rec.institution_id) or (can_write(u) and rec.owner_id == u.id)
    if admin_for(u, rec.institution_id):
        return True
    if rec.kind in PERSONAL_KINDS:
        return rec.owner_id == u.id or rec.recipient_id == u.id
    return can_write(u) and rec.owner_id == u.id


def can_write_observation(u: User) -> bool:
    return is_admin(u) or (u.is_active and u.role == R.PSYCHOLOGIST.value)
