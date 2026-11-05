import re

from fastapi.testclient import TestClient
from sqlalchemy import select

from app.main import create_app
from app.models import AuditEvent, Role, User

from conftest import Api, add_institution, add_student, add_user, db_session, make_settings


def _admin(app, email="boss@maktab.uz"):
    return add_user(app, email, Role.SUPER_ADMIN, mfa=True)


def test_admin_routes_hidden_from_everyone_else(api, app):
    inst = add_institution(app)
    add_user(app, "psy@maktab.uz", Role.PSYCHOLOGIST, inst)
    api.login("psy@maktab.uz")
    for path in ["/api/admin/users", "/api/admin/audit", "/api/admin/sessions"]:
        assert api.get(path).status_code == 404
    assert api.post("/api/admin/users", {"email": "x@y.uz", "full_name": "Xx Yy", "role": "SUPER_ADMIN"}).status_code == 404
    with db_session(app) as db:
        assert db.scalar(select(AuditEvent).where(AuditEvent.action == "ADMIN_ACCESS_DENIED"))


def test_unauthenticated_admin_access_rejected(client):
    assert client.get("/api/admin/users").status_code == 401


def test_owner_admin_with_2fa_has_full_access(api, app):
    a = _admin(app)
    api.login("boss@maktab.uz", mfa_secret=a.mfa_secret)
    assert api.get("/api/admin/users").status_code == 200
    assert api.get("/api/admin/audit").status_code == 200


def test_admin_without_completed_2fa_is_blocked(api, app):
    _admin(app)
    r = api.login("boss@maktab.uz")  # password only
    assert r.json()["state"] == "mfa_required"
    assert api.get("/api/admin/users").status_code == 403


def test_admin_ip_allowlist():
    app = create_app(make_settings(admin_ip_allowlist=["203.0.113.0/24"]))
    a = _admin(app)
    api = Api(TestClient(app))
    api.login("boss@maktab.uz", mfa_secret=a.mfa_secret)
    assert api.get("/api/admin/users").status_code == 404  # test client IP is not allowed


def test_create_user_mails_temporary_password_and_never_returns_it(api, app):
    a = _admin(app)
    api.login("boss@maktab.uz", mfa_secret=a.mfa_secret)
    r = api.post("/api/admin/users", {"email": "New@Maktab.uz", "full_name": "Yangi Xodim", "role": "TEACHER"})
    assert r.status_code == 201
    mail = app.state.ctx.mailer.outbox[-1]
    temp = re.search(r"Vaqtinchalik parol: (\S+)", mail.body).group(1)
    assert temp not in r.text
    assert r.json()["must_change_password"] is True
    other = Api(TestClient(app))
    assert other.login("new@maktab.uz", temp).json()["state"] == "password_change_required"


def test_last_admin_cannot_be_demoted_and_no_self_change(api, app):
    a = _admin(app)
    api.login("boss@maktab.uz", mfa_secret=a.mfa_secret)
    r = api.patch(f"/api/admin/users/{a.id}", {"is_active": False})
    assert r.status_code == 409
    b = add_user(app, "b2@maktab.uz", Role.SUPER_ADMIN, mfa=True)
    with db_session(app) as db:
        db.get(User, b.id).is_active = False
        db.commit()
    r = api.patch(f"/api/admin/users/{a.id}", {"role": "TEACHER"})
    assert r.status_code == 409


def test_blocking_user_revokes_their_sessions(api, app):
    a = _admin(app)
    inst = add_institution(app)
    t = add_user(app, "t@maktab.uz", Role.TEACHER, inst)
    victim = Api(TestClient(app))
    victim.login("t@maktab.uz")
    api.login("boss@maktab.uz", mfa_secret=a.mfa_secret)
    assert api.patch(f"/api/admin/users/{t.id}", {"is_active": False}).status_code == 200
    assert victim.get("/api/auth/me").status_code == 401


# ------------------------------------------------------------------ data access rules

def test_other_school_students_are_invisible(api, app):
    a, b = add_institution(app, "A"), add_institution(app, "B")
    add_user(app, "coord@a.uz", Role.COORDINATOR, a)
    sid = add_student(app, b)
    api.login("coord@a.uz")
    assert api.get(f"/api/students/{sid}").status_code == 404
    assert api.get("/api/students").json() == []


def test_specialist_sees_only_assigned_children(api, app):
    inst = add_institution(app)
    me = add_user(app, "psy@a.uz", Role.PSYCHOLOGIST, inst)
    mine = add_student(app, inst, specialists=[me.id])
    other = add_student(app, inst)
    api.login("psy@a.uz")
    ids = [s["id"] for s in api.get("/api/students").json()]
    assert ids == [mine]
    assert api.get(f"/api/students/{other}").status_code == 404


def test_teacher_does_not_see_diagnosis_or_confidential_notes(api, app):
    inst = add_institution(app)
    psy = add_user(app, "psy@a.uz", Role.PSYCHOLOGIST, inst)
    teacher = add_user(app, "tch@a.uz", Role.TEACHER, inst)
    sid = add_student(app, inst, specialists=[psy.id, teacher.id])

    p = Api(TestClient(app))
    p.login("psy@a.uz")
    assert p.post(f"/api/students/{sid}/observations", {"text": "Maxfiy kuzatuv", "confidential": True}).status_code == 201

    api.login("tch@a.uz")
    s = api.get(f"/api/students/{sid}").json()
    assert s["diagnosis"] is None and s["guardian_phone"] is None
    assert api.get(f"/api/students/{sid}/observations").json() == []
    assert api.post(f"/api/students/{sid}/observations", {"text": "x"}).status_code == 403


def test_reviewer_cannot_create_assessments(api, app):
    inst = add_institution(app)
    add_user(app, "rev@a.uz", Role.REVIEWER, inst)
    sid = add_student(app, inst)
    api.login("rev@a.uz")
    r = api.post(f"/api/students/{sid}/assessments",
                 {"title": "Test", "assessment_date": "2026-10-01", "total_score": 1, "max_score": 2})
    assert r.status_code == 403


def test_cannot_create_student_in_another_school(api, app):
    a, b = add_institution(app, "A"), add_institution(app, "B")
    add_user(app, "coord@a.uz", Role.COORDINATOR, a)
    api.login("coord@a.uz")
    r = api.post("/api/students", {"full_name": "Bola Bir", "birth_date": "2016-01-01", "institution_id": b})
    assert r.status_code == 201 and r.json()["institution_id"] == a  # forced to own school


def test_institutions_list_counts_active_accounts_and_refuses_duplicates(api, app):
    a = _admin(app)
    api.login("boss@maktab.uz", mfa_secret=a.mfa_secret)
    r = api.post("/api/admin/institutions", {"name": "14-sonli maktab", "region": "Namangan"})
    assert r.status_code == 201
    inst = r.json()["id"]
    add_user(app, "t1@maktab.uz", Role.TEACHER, inst)
    assert api.post("/api/admin/institutions", {"name": "14-SONLI MAKTAB"}).status_code == 409
    rows = api.get("/api/admin/institutions").json()
    assert rows == [{"id": inst, "name": "14-sonli maktab", "region": "Namangan", "users": 1}]


def test_moving_a_user_to_another_school_signs_them_out(api, app, client):
    a = _admin(app)
    first, second = add_institution(app, "1-maktab"), add_institution(app, "2-maktab")
    u = add_user(app, "mv@maktab.uz", Role.PSYCHOLOGIST, first)
    other = Api(type(client)(app))
    other.login("mv@maktab.uz")
    api.login("boss@maktab.uz", mfa_secret=a.mfa_secret)
    r = api.patch(f"/api/admin/users/{u.id}", {"institution_id": second})
    assert r.status_code == 200 and r.json()["institution_id"] == second
    assert other.get("/api/auth/me").status_code == 401
    assert api.patch(f"/api/admin/users/{u.id}", {"institution_id": "f" * 32}).status_code == 422
