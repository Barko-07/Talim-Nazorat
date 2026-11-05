"""Who sees which child. The rule: administrators see their scope; everyone
else only the children they are assigned to - not their colleagues' children,
and nothing from another school."""
from fastapi.testclient import TestClient
from sqlalchemy import select

from app.mailer import MailError
from app.models import AuditEvent, Role

from conftest import Api, add_institution, add_user, db_session, last_code_for, make_settings


def _as(app, email, **kw):
    a = Api(TestClient(app))
    r = a.login(email, **kw)
    assert r.status_code == 200 and r.json()["state"] == "ok", r.text
    return a


def _put(a, *ops):
    return a.post("/api/records/batch", {"ops": [
        {"op": "put", "kind": k, "id": i, "data": d} for k, i, d in ops]})


def _items(a, kind):
    r = a.get("/api/records")
    assert r.status_code == 200, r.text
    return r.json()["items"][kind]


def _school(app, name="1-maktab"):
    inst = add_institution(app, name)
    add_user(app, f"t1@{name}.uz", Role.TEACHER, inst)
    add_user(app, f"t2@{name}.uz", Role.TEACHER, inst)
    add_user(app, f"psy@{name}.uz", Role.PSYCHOLOGIST, inst)
    add_user(app, f"dir@{name}.uz", Role.INSTITUTION_ADMIN, inst)
    return inst


def _boss(app):
    add_user(app, "boss@maktab.uz", Role.SUPER_ADMIN)
    return _as(app, "boss@maktab.uz")


def test_a_teacher_sees_only_their_own_children_not_a_colleagues(app):
    _school(app)
    t1, t2 = _as(app, "t1@1-maktab.uz"), _as(app, "t2@1-maktab.uz")
    assert _put(t1, ("student", "s1", {"firstName": "Ali"}),
                ("assessment", "a1", {"studentId": "s1", "score": 7})).status_code == 200

    assert [s["id"] for s in _items(t1, "student")] == ["s1"]
    assert _items(t2, "student") == [] and _items(t2, "assessment") == []
    # Guessing the id does not help: writing to it looks like "not found".
    assert _put(t2, ("student", "s1", {"firstName": "X"})).status_code == 404
    assert _put(t2, ("assessment", "a2", {"studentId": "s1"})).status_code == 404


def test_other_school_sees_nothing_and_admins_see_their_scope(app):
    _school(app, "1-maktab")
    _school(app, "2-maktab")
    _put(_as(app, "t1@1-maktab.uz"), ("student", "s1", {"firstName": "Ali"}))
    _put(_as(app, "t1@2-maktab.uz"), ("student", "s2", {"firstName": "Vali"}))

    assert [s["id"] for s in _items(_as(app, "dir@1-maktab.uz"), "student")] == ["s1"]
    assert [s["id"] for s in _items(_as(app, "dir@2-maktab.uz"), "student")] == ["s2"]
    assert sorted(s["id"] for s in _items(_boss(app), "student")) == ["s1", "s2"]


def test_only_an_administrator_can_give_a_colleague_access(app):
    inst = _school(app)
    t1, t2 = _as(app, "t1@1-maktab.uz"), _as(app, "t2@1-maktab.uz")
    with db_session(app) as db:
        from app.models import User
        t2_id = db.scalar(select(User.id).where(User.email == "t2@1-maktab.uz"))
    _put(t1, ("student", "s1", {"firstName": "Ali"}))
    # A teacher cannot widen access by editing the assignment list (refused
    # openly), nor move the child to another school (ignored).
    r = _put(t1, ("student", "s1", {"firstName": "Ali", "assignedSpecialistIds": [t2_id]}))
    assert r.status_code == 403
    r = _put(t1, ("student", "s1", {"firstName": "Ali", "institutionId": "f" * 32}))
    assert r.status_code == 200 and r.json()["items"][0]["data"]["institutionId"] == inst
    assert _items(t2, "student") == []
    # ...the school administrator can.
    d = _as(app, "dir@1-maktab.uz")
    assert _put(d, ("student", "s1", {"firstName": "Ali", "assignedSpecialistIds": [t2_id]})).status_code == 200
    assert [s["id"] for s in _items(t2, "student")] == ["s1"]
    # And can take it away again.
    _put(d, ("student", "s1", {"firstName": "Ali", "assignedSpecialistIds": []}))
    assert _items(t2, "student") == []


def test_staff_from_another_school_cannot_be_assigned(app):
    _school(app, "1-maktab")
    _school(app, "2-maktab")
    with db_session(app) as db:
        from app.models import User
        outsider = db.scalar(select(User.id).where(User.email == "t1@2-maktab.uz"))
    d = _as(app, "dir@1-maktab.uz")
    r = _put(d, ("student", "s1", {"firstName": "Ali", "assignedSpecialistIds": [outsider]}))
    assert r.status_code == 422


def test_confidential_notes_only_author_and_administrators(app):
    _school(app)
    with db_session(app) as db:
        from app.models import User
        ids = {u.email: u.id for u in db.scalars(select(User))}
    d = _as(app, "dir@1-maktab.uz")
    _put(d, ("student", "s1", {"firstName": "Ali", "assignedSpecialistIds": [
        ids["t1@1-maktab.uz"], ids["psy@1-maktab.uz"]]}))
    psy, t1 = _as(app, "psy@1-maktab.uz"), _as(app, "t1@1-maktab.uz")
    assert _put(psy, ("observation", "o1", {"studentId": "s1", "isConfidential": True, "text": "maxfiy"}),
                ("observation", "o2", {"studentId": "s1", "isConfidential": False, "text": "ochiq"})).status_code == 200
    assert [o["id"] for o in _items(t1, "observation")] == ["o2"]
    assert sorted(o["id"] for o in _items(d, "observation")) == ["o1", "o2"]
    # Teachers do not write psychologist's notes, and cannot rewrite a confidential one.
    assert _put(t1, ("observation", "o3", {"studentId": "s1"})).status_code == 403
    assert _put(t1, ("observation", "o1", {"studentId": "s1", "text": "x"})).status_code == 404


def test_items_never_move_to_another_child_and_reviewers_only_read(app):
    inst = _school(app)
    add_user(app, "rev@1-maktab.uz", Role.REVIEWER, inst)
    t1 = _as(app, "t1@1-maktab.uz")
    _put(t1, ("student", "s1", {}), ("student", "s2", {}), ("session", "x1", {"studentId": "s1"}))
    r = _put(t1, ("session", "x1", {"studentId": "s2"}))
    assert r.json()["items"][0]["data"]["studentId"] == "s1"
    rev = _as(app, "rev@1-maktab.uz")
    assert _put(rev, ("student", "s9", {})).status_code == 403


def test_a_batch_is_all_or_nothing(app):
    _school(app)
    t1, t2 = _as(app, "t1@1-maktab.uz"), _as(app, "t2@1-maktab.uz")
    _put(t2, ("student", "theirs", {}))
    r = _put(t1, ("student", "mine", {}), ("session", "x", {"studentId": "theirs"}))
    assert r.status_code == 404 and r.json()["index"] == 1
    assert _items(t1, "student") == []  # the first operation was rolled back too


def test_deleting_children_is_for_administrators_and_hides_everything(app):
    _school(app)
    t1, d = _as(app, "t1@1-maktab.uz"), _as(app, "dir@1-maktab.uz")
    _put(t1, ("student", "s1", {}), ("session", "x1", {"studentId": "s1"}))
    delete = {"ops": [{"op": "delete", "kind": "student", "id": "s1"}]}
    assert t1.post("/api/records/batch", delete).status_code == 403
    assert d.post("/api/records/batch", delete).status_code == 200
    assert _items(t1, "student") == [] and _items(t1, "session") == []
    assert _items(d, "student") == []


def test_administrator_sees_every_change_with_old_and_new_values(app):
    _school(app)
    t1 = _as(app, "t1@1-maktab.uz")
    _put(t1, ("student", "s1", {"firstName": "Ali", "lastName": "Valiyev"}))
    _put(t1, ("student", "s1", {"firstName": "Alisher", "lastName": "Valiyev"}))
    _items(t1, "student")
    boss = _boss(app)
    rows = boss.get("/api/admin/changes").json()
    assert [r["action"] for r in rows] == ["update", "create"]
    upd = rows[0]
    assert upd["fields"] == ["firstName"]
    assert upd["before"] == {"firstName": "Ali"} and upd["after"] == {"firstName": "Alisher"}
    assert upd["student_name"] == "Valiyev Alisher" and upd["user_name"]
    # Nobody else can read the history.
    assert t1.get("/api/admin/changes").status_code == 404
    with db_session(app) as db:
        assert db.scalar(select(AuditEvent).where(AuditEvent.action == "ADMIN_CHANGES_VIEWED"))
        assert db.scalar(select(AuditEvent).where(AuditEvent.action == "RECORDS_READ"))


def test_directory_has_names_only_and_stays_inside_the_school(app):
    _school(app, "1-maktab")
    _school(app, "2-maktab")
    rows = _as(app, "t1@1-maktab.uz").get("/api/directory").json()
    assert len(rows) == 4 and all(set(r) == {"id", "full_name", "role", "institution_id"} for r in rows)


def test_moving_a_teacher_to_another_school_removes_their_children(app):
    _school(app, "1-maktab")
    second = _school(app, "2-maktab")
    _put(_as(app, "t1@1-maktab.uz"), ("student", "s1", {}))
    with db_session(app) as db:
        from app.models import User
        uid = db.scalar(select(User.id).where(User.email == "t1@1-maktab.uz"))
    boss = _boss(app)
    assert boss.patch(f"/api/admin/users/{uid}", {"institution_id": second}).status_code == 200
    assert _items(_as(app, "t1@1-maktab.uz"), "student") == []


def test_notifications_reach_only_their_recipient_in_the_same_school(app):
    _school(app, "1-maktab")
    _school(app, "2-maktab")
    with db_session(app) as db:
        from app.models import User
        ids = {u.email: u.id for u in db.scalars(select(User))}
    t1 = _as(app, "t1@1-maktab.uz")
    assert _put(t1, ("notification", "n1", {"recipientUserId": ids["t2@1-maktab.uz"], "title": "Salom"})
                ).status_code == 200
    assert _put(t1, ("notification", "n2", {"recipientUserId": ids["t1@2-maktab.uz"]})).status_code == 404
    assert [n["id"] for n in _items(_as(app, "t2@1-maktab.uz"), "notification")] == ["n1"]
    assert _items(_as(app, "psy@1-maktab.uz"), "notification") == []


# ------------------------------------------------------------------ login hardening


def test_failed_mail_cancels_the_code_and_allows_an_immediate_retry():
    from app.main import create_app
    app = create_app(make_settings(code_resend_seconds=60))
    inst = add_institution(app)
    add_user(app, "dir@m.uz", Role.INSTITUTION_ADMIN, inst)
    api = Api(TestClient(app))
    mailer = app.state.ctx.mailer
    real = mailer.send

    def broken(*a, **k):
        raise MailError("down")

    mailer.send = broken
    r = api.post("/api/auth/login", {"email": "dir@m.uz", "password": "Xavfsiz-Parol-2026"})
    assert r.status_code == 503 and r.json()["code"] == "mail_failed"
    mailer.send = real
    r = api.post("/api/auth/login", {"email": "dir@m.uz", "password": "Xavfsiz-Parol-2026"})
    assert r.status_code == 200 and r.json()["state"] == "email_code_required"
    assert api.post("/api/auth/email-code/verify", {"code": last_code_for(app, "dir@m.uz")}).status_code == 200


def test_emailed_codes_stop_working_after_too_many_wrong_guesses_in_a_day():
    from app.main import create_app
    app = create_app(make_settings(code_daily_failures=3))
    inst = add_institution(app)
    add_user(app, "dir@m.uz", Role.INSTITUTION_ADMIN, inst)
    api = Api(TestClient(app))
    api.post("/api/auth/login", {"email": "dir@m.uz", "password": "Xavfsiz-Parol-2026"})
    code = last_code_for(app, "dir@m.uz")
    wrong = "000000" if code != "000000" else "111111"
    for _ in range(3):
        assert api.post("/api/auth/email-code/verify", {"code": wrong}).status_code == 401
    assert api.post("/api/auth/email-code/verify", {"code": code}).status_code == 401


def test_wrong_passwords_from_one_address_do_not_lock_the_owner_out():
    from app.main import create_app
    app = create_app(make_settings(trusted_proxies=["testclient"]))
    add_user(app, "t@m.uz", Role.TEACHER, add_institution(app))
    c = TestClient(app)
    h = {"X-Requested-With": "XMLHttpRequest"}
    for _ in range(6):
        c.post("/api/auth/login", json={"email": "t@m.uz", "password": "Notogri-1234"},
               headers={**h, "X-Real-IP": "203.0.113.9"})
    attacker = c.post("/api/auth/login", json={"email": "t@m.uz", "password": "Xavfsiz-Parol-2026"},
                      headers={**h, "X-Real-IP": "203.0.113.9"})
    assert attacker.status_code == 401
    owner = TestClient(app).post("/api/auth/login", json={"email": "t@m.uz", "password": "Xavfsiz-Parol-2026"},
                                 headers={**h, "X-Real-IP": "198.51.100.7"})
    assert owner.status_code == 200
