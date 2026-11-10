import re

from fastapi.testclient import TestClient
from sqlalchemy import select

from app.main import create_app
from app.models import AuditEvent, Role, User

from conftest import Api, add_institution, add_user, db_session, make_settings


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
    inst = add_institution(app)
    api.login("boss@maktab.uz", mfa_secret=a.mfa_secret)
    r = api.post("/api/admin/users", {"email": "New@Maktab.uz", "full_name": "Yangi Xodim", "role": "TEACHER"})
    assert r.status_code == 422  # a teacher always belongs to a school
    r = api.post("/api/admin/users", {"email": "New@Maktab.uz", "full_name": "Yangi Xodim", "role": "TEACHER",
                                      "institution_id": inst})
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


def test_institutions_list_counts_active_accounts_and_refuses_duplicates(api, app):
    a = _admin(app)
    api.login("boss@maktab.uz", mfa_secret=a.mfa_secret)
    r = api.post("/api/admin/institutions", {"name": "14-sonli maktab", "region": "Namangan"})
    assert r.status_code == 201
    inst = r.json()["id"]
    add_user(app, "t1@maktab.uz", Role.TEACHER, inst)
    add_user(app, "t2@maktab.uz", Role.TEACHER, inst, active=False)  # blocked: not counted
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


# ------------------------------------------------------------------ school administrators


def _dir(app, inst, email="dir@a.uz"):
    add_user(app, email, Role.INSTITUTION_ADMIN, inst)
    a = Api(TestClient(app))
    assert a.login(email).json()["state"] == "ok"
    return a


def _register(app, email, school_name):
    """A sign-up waiting for approval that named `school_name`."""
    from app.models import User as U
    import json as _json
    with db_session(app) as db:
        u = U(email=email, full_name="Ariza Beruvchi", role=Role.TEACHER.value,
              password_hash="x", pending_approval=True, must_change_password=False,
              profile=_json.dumps({"institution_name": school_name}))
        db.add(u)
        db.commit()
        return u.id


def test_school_admin_sees_and_manages_only_their_school(app):
    a, b = add_institution(app, "1-sonli maktab"), add_institution(app, "2-sonli maktab")
    mine = add_user(app, "t@a.uz", Role.TEACHER, a)
    theirs = add_user(app, "t@b.uz", Role.TEACHER, b)
    other_admin = add_user(app, "dir2@a.uz", Role.INSTITUTION_ADMIN, a)
    asking_mine = _register(app, "new1@x.uz", "1-sonli  Maktab")
    asking_theirs = _register(app, "new2@x.uz", "2-sonli maktab")
    d = _dir(app, a)

    emails = {u["email"] for u in d.get("/api/admin/users").json()}
    assert {"t@a.uz", "new1@x.uz"} <= emails
    assert "t@b.uz" not in emails and "new2@x.uz" not in emails

    assert d.patch(f"/api/admin/users/{mine.id}", {"is_active": False}).status_code == 200
    assert d.patch(f"/api/admin/users/{theirs.id}", {"is_active": False}).status_code == 404
    assert d.patch(f"/api/admin/users/{other_admin.id}", {"is_active": False}).status_code == 404
    assert d.patch(f"/api/admin/users/{mine.id}", {"role": "SUPER_ADMIN"}).status_code == 403
    assert d.patch(f"/api/admin/users/{mine.id}", {"institution_id": b}).status_code == 403

    assert d.post(f"/api/admin/users/{asking_theirs}/approve", {"institution_id": a}).status_code == 404
    assert d.post(f"/api/admin/users/{asking_mine}/approve", {"institution_id": b}).status_code == 403
    assert d.post(f"/api/admin/users/{asking_mine}/approve", {"institution_id": a}).status_code == 200

    assert [i["id"] for i in d.get("/api/admin/institutions").json()] == [a]
    assert d.post("/api/admin/institutions", {"name": "3-sonli maktab"}).status_code == 403


def test_school_admin_creates_staff_only_for_their_school_and_never_admins(app):
    a, b = add_institution(app, "A"), add_institution(app, "B")
    d = _dir(app, a)
    r = d.post("/api/admin/users", {"email": "n@a.uz", "full_name": "Yangi Xodim", "role": "TEACHER"})
    assert r.status_code == 201 and r.json()["institution_id"] == a
    assert d.post("/api/admin/users", {"email": "x@a.uz", "full_name": "Yangi Xodim", "role": "TEACHER",
                                       "institution_id": b}).status_code == 403
    assert d.post("/api/admin/users", {"email": "y@a.uz", "full_name": "Yangi Admin",
                                       "role": "INSTITUTION_ADMIN"}).status_code == 403


def test_school_admin_history_and_audit_cover_only_their_school(app):
    a, b = add_institution(app, "A"), add_institution(app, "B")
    add_user(app, "t@a.uz", Role.TEACHER, a)
    add_user(app, "t@b.uz", Role.TEACHER, b)
    for email, rid in (("t@a.uz", "sa"), ("t@b.uz", "sb")):
        t = Api(TestClient(app))
        t.login(email)
        assert t.post("/api/records/batch", {"ops": [{"op": "put", "kind": "student", "id": rid,
                                                       "data": {"firstName": rid}}]}).status_code == 200
    d = _dir(app, a)
    assert [c["record_id"] for c in d.get("/api/admin/changes").json()] == ["sa"]
    users = {e["user_id"] for e in d.get("/api/admin/audit").json()}
    with db_session(app) as db:
        b_ids = {u.id for u in db.scalars(select(User).where(User.institution_id == b))}
    assert not users & b_ids


# ------------------------------------------------------------------ own profile


def test_people_edit_only_their_own_profile_and_admins_see_the_change(app):
    inst = add_institution(app)
    add_user(app, "t@a.uz", Role.TEACHER, inst)
    t = Api(TestClient(app))
    t.login("t@a.uz")
    r = t.patch("/api/auth/profile", {"first_name": "Dilnoza", "last_name": "Karimova",
                                      "phone": "+998 90 111-22-33", "specialization": "Matematika",
                                      "experience_years": 7})
    assert r.status_code == 200
    me = r.json()["user"]
    assert me["full_name"] == "Karimova Dilnoza" and me["phone"] == "+998 90 111 22 33"  # stored one way
    assert me["profile"]["specialization"] == "Matematika" and me["profile"]["experience_years"] == 7
    # Email, role and school cannot be changed this way.
    for bad in ({"email": "x@y.uz"}, {"role": "SUPER_ADMIN"}, {"institution_id": "f" * 32}):
        assert t.patch("/api/auth/profile", bad).status_code == 422
    assert t.patch("/api/auth/profile", {"first_name": "<b>x</b>"}).status_code == 422
    # The school administrator sees what changed.
    d = _dir(app, inst)
    row = next(c for c in d.get("/api/admin/changes").json() if c["kind"] == "profile")
    assert "full_name" in row["fields"] and "phone" in row["fields"]
    # Only which fields changed: the history cannot be erased, and a deleted
    # account's name and phone must disappear.
    assert row["before"] is None and row["after"] is None


def test_the_signed_in_user_carries_their_actual_school_name(app):
    inst = add_institution(app, "14-sonli maktab")
    add_user(app, "t14@a.uz", Role.TEACHER, inst)
    t = Api(TestClient(app))
    me = t.login("t14@a.uz").json()["user"]
    assert me["institution_id"] == inst and me["institution_name"] == "14-sonli maktab"
