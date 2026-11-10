"""Login rules: teachers and specialists sign in with their password ("Eslab
qolish" keeps them signed in); admins also confirm every login with an emailed
code (or the authenticator, with recovery codes). Sign-up confirms the email."""
import re
from datetime import timedelta

import pytest

from fastapi.testclient import TestClient
from sqlalchemy import select, update

from app.main import create_app
from app.models import AuthSession, OneTimeCode, PendingRegistration, Role, User, utcnow
from app.security import passwords

from conftest import (
    PASSWORD,
    Api,
    add_institution,
    add_user,
    db_session,
    last_code_for,
    make_settings,
    totp_now,
)

NEW = "Yangi-Mustahkam-Parol-77"


def _live_session(app) -> AuthSession:
    with db_session(app) as db:
        return db.scalars(select(AuthSession).where(AuthSession.revoked.is_(False))).one()


# ------------------------------------------------------------------ password only for non-admins

def test_every_sign_in_needs_the_code_emailed_to_the_account(api, app):
    add_user(app, "t@maktab.uz", Role.TEACHER)
    r = api.login("t@maktab.uz", email_code=False)
    assert r.status_code == 200 and r.json()["state"] == "email_code_required"
    assert r.json()["user"]["can_stay_signed_in"] is True
    assert [m.to for m in app.state.ctx.mailer.outbox] == ["t@maktab.uz"]
    # The password alone opens nothing.
    assert api.get("/api/records").status_code == 403
    code = last_code_for(app, "t@maktab.uz")
    r = api.post("/api/auth/email-code/verify", {"code": code})
    assert r.status_code == 200 and r.json()["state"] == "ok"
    assert api.get("/api/records").status_code == 200


def test_a_partial_sign_in_is_never_kept_for_days(api, app):
    add_user(app, "p@maktab.uz", Role.TEACHER)
    r = api.login("p@maktab.uz", email_code=False, remember=True)
    assert r.json()["state"] == "email_code_required"
    assert "max-age=2592000" not in r.headers["set-cookie"].lower()
    assert _live_session(app).remember is False


def test_without_eslab_qolish_the_session_ends_after_30_idle_minutes(api, app):
    add_user(app, "short@maktab.uz")
    api.login("short@maktab.uz")
    assert _live_session(app).remember is False
    with db_session(app) as db:
        db.execute(update(AuthSession).values(last_seen_at=utcnow() - timedelta(minutes=31)))
        db.commit()
    assert api.get("/api/auth/me").status_code == 401


def test_eslab_qolish_keeps_a_teacher_signed_in_for_30_days(api, app, client):
    add_user(app, "long@maktab.uz")
    r = api.login("long@maktab.uz", remember=True)
    assert r.json()["state"] == "ok"
    assert "max-age=2592000" in r.headers["set-cookie"].lower()  # 30 days
    assert _live_session(app).remember is True
    with db_session(app) as db:  # a week without opening the app
        db.execute(update(AuthSession).values(last_seen_at=utcnow() - timedelta(days=7),
                                              created_at=utcnow() - timedelta(days=7)))
        db.commit()
    assert api.get("/api/auth/me").status_code == 200
    with db_session(app) as db:
        db.execute(update(AuthSession).values(created_at=utcnow() - timedelta(days=31)))
        db.commit()
    assert api.get("/api/auth/me").status_code == 401


def test_password_change_keeps_eslab_qolish_but_signs_out_other_devices(api, app, client):
    add_user(app, "keep@maktab.uz")
    other = Api(type(client)(app))
    other.login("keep@maktab.uz")
    api.login("keep@maktab.uz", remember=True)
    api.post("/api/auth/password/change/request")
    code = last_code_for(app, "keep@maktab.uz")
    assert api.post("/api/auth/password/change",
                    {"current_password": PASSWORD, "code": code, "new_password": NEW}).status_code == 200
    assert other.get("/api/auth/me").status_code == 401
    assert _live_session(app).remember is True


# ------------------------------------------------------------------ admins: emailed code every time

def test_admin_login_needs_the_emailed_code(api, app):
    add_user(app, "boss@maktab.uz", Role.SUPER_ADMIN)
    r = api.login("boss@maktab.uz", email_code=False)
    assert r.status_code == 200 and r.json()["state"] == "email_code_required"
    assert r.json()["user"]["can_stay_signed_in"] is False
    assert "kirish kodi" in app.state.ctx.mailer.outbox[-1].subject
    assert api.get("/api/admin/users").status_code == 403  # password alone opens nothing

    code = last_code_for(app, "boss@maktab.uz")
    wrong = "000000" if code != "000000" else "111111"
    assert api.post("/api/auth/email-code/verify", {"code": wrong}).status_code == 401
    r = api.post("/api/auth/email-code/verify", {"code": code})
    assert r.status_code == 200 and r.json()["state"] == "ok"
    assert api.post("/api/auth/email-code/verify", {"code": code}).status_code == 403  # already done


def test_admin_cannot_use_eslab_qolish(api, app):
    add_user(app, "boss@maktab.uz", Role.SUPER_ADMIN)
    r = api.login("boss@maktab.uz", remember=True)
    assert r.json()["state"] == "ok"
    assert _live_session(app).remember is False
    api.post("/api/auth/logout")
    assert api.login("boss@maktab.uz", email_code=False).json()["state"] == "email_code_required"


def test_school_director_also_confirms_with_the_code(api, app):
    inst = add_institution(app)
    add_user(app, "dir@maktab.uz", Role.INSTITUTION_ADMIN, inst)
    assert api.login("dir@maktab.uz", email_code=False).json()["state"] == "email_code_required"


def test_login_code_is_single_use_and_attempts_are_limited(api, app):
    add_user(app, "a@maktab.uz", Role.SUPER_ADMIN)
    api.login("a@maktab.uz", email_code=False)
    code = last_code_for(app, "a@maktab.uz")
    wrong = "000000" if code != "000000" else "111111"
    for _ in range(5):
        api.post("/api/auth/email-code/verify", {"code": wrong})
    # the 6th try - even with the right code - is refused: the code was burnt
    assert api.post("/api/auth/email-code/verify", {"code": code}).status_code == 401


def test_each_code_email_has_its_own_subject(api, app):
    # Same subject = one Gmail conversation; the code in the subject keeps them apart.
    add_user(app, "s@maktab.uz", Role.SUPER_ADMIN)
    api.login("s@maktab.uz", email_code=False)
    api.post("/api/auth/email-code/send")
    mails = [m for m in app.state.ctx.mailer.outbox if m.to == "s@maktab.uz"][-2:]
    for mail in mails:
        code = re.search(r"\b(\d{6})\b", mail.body).group(1)
        assert mail.subject.startswith(code)


def test_resend_waits_a_minute_between_codes():
    app = create_app(make_settings(code_resend_seconds=60))
    api = Api(TestClient(app))
    add_user(app, "w@maktab.uz", Role.SUPER_ADMIN)
    r = api.login("w@maktab.uz", email_code=False)
    assert r.json()["resend_after"] == 60
    r = api.post("/api/auth/email-code/send")
    assert r.status_code == 429 and 0 < r.json()["retry_after"] <= 60

    with db_session(app) as db:
        db.execute(update(OneTimeCode).values(created_at=utcnow() - timedelta(seconds=61)))
        db.commit()
    first = last_code_for(app, "w@maktab.uz")
    r = api.post("/api/auth/email-code/send")
    assert r.status_code == 200
    second = last_code_for(app, "w@maktab.uz")
    if first != second:  # the old code stops working once a new one is sent
        assert api.post("/api/auth/email-code/verify", {"code": first}).status_code == 401
    assert api.post("/api/auth/email-code/verify", {"code": second}).json()["state"] == "ok"


# ------------------------------------------------------------------ authenticator + recovery codes

def _enable_mfa(api) -> tuple[str, list[str]]:
    secret = api.post("/api/auth/mfa/setup", {"password": PASSWORD}).json()["secret"]
    r = api.post("/api/auth/mfa/enable", {"code": totp_now(secret)})
    assert r.status_code == 200
    return secret, r.json()["recovery_codes"]


def test_enabling_mfa_gives_ten_single_use_recovery_codes(api, app):
    add_user(app, "adm@maktab.uz", Role.SUPER_ADMIN)
    api.login("adm@maktab.uz")
    _, codes = _enable_mfa(api)
    assert len(codes) == 10 and len(set(codes)) == 10
    api.post("/api/auth/logout")

    assert api.login("adm@maktab.uz").json()["state"] == "mfa_required"  # no email code once TOTP is on
    r = api.post("/api/auth/mfa/recovery", {"code": codes[0].lower()})
    assert r.status_code == 200 and r.json()["state"] == "ok" and r.json()["recovery_codes_left"] == 9
    assert "zaxira kod" in app.state.ctx.mailer.outbox[-1].subject
    api.post("/api/auth/logout")

    api.login("adm@maktab.uz")
    assert api.post("/api/auth/mfa/recovery", {"code": codes[0]}).status_code == 401  # used
    assert api.post("/api/auth/mfa/recovery", {"code": "ABCD-EFGH"}).status_code == 401


def test_forced_change_of_temporary_password_needs_no_second_code(api, app):
    add_user(app, "tmp@maktab.uz", must_change=True)
    assert api.login("tmp@maktab.uz").json()["state"] == "password_change_required"
    r = api.post("/api/auth/password/change", {"current_password": PASSWORD, "new_password": NEW})
    assert r.status_code == 200 and r.json()["state"] == "ok"


def test_voluntary_password_change_still_needs_the_emailed_code(api, app):
    add_user(app, "vol@maktab.uz")
    api.login("vol@maktab.uz")
    r = api.post("/api/auth/password/change", {"current_password": PASSWORD, "new_password": NEW})
    assert r.status_code == 401


# ------------------------------------------------------------------ sign-up

FORM = {
    "first_name": "Dilnoza", "last_name": "Karimova", "email": "dilnoza@maktab.uz",
    "phone": "+998901112233", "role": "PSYCHOLOGIST", "specialization": "Psixolog",
    "qualification_category": "Birinchi", "experience_years": 4, "region": "Namangan viloyati",
    "district": "Namangan shahri", "institution_name": "14-sonli maktab", "password": NEW,
}


@pytest.fixture(autouse=True)
def _school(app):
    """Sign-ups pick their school from the public list: it has to exist."""
    return add_institution(app, "14-sonli maktab")


def test_sign_up_code_signs_the_person_into_their_school(api, app, _school):
    r = api.post("/api/auth/register", FORM)
    assert r.status_code == 202
    reg_id = r.json()["registration_id"]
    code = last_code_for(app, FORM["email"])
    with db_session(app) as db:
        assert db.scalar(select(User).where(User.email == FORM["email"])) is None  # no account yet

    bad = "000000" if code != "000000" else "111111"
    assert api.post("/api/auth/register/verify", {"registration_id": reg_id, "code": bad}).status_code == 400
    r = api.post("/api/auth/register/verify", {"registration_id": reg_id, "code": code})
    # No administrator approval and no second code: the person is in.
    assert r.status_code == 200 and r.json()["state"] == "ok"
    assert r.json()["user"]["institution_id"] == _school
    assert r.json()["user"]["institution_name"] == "14-sonli maktab"
    with db_session(app) as db:
        u = db.scalar(select(User).where(User.email == FORM["email"]))
        assert u.is_active and not u.pending_approval

    # Later sign-ins work as for everyone (password + emailed code).
    fresh = Api(TestClient(app))
    r = fresh.login(FORM["email"], NEW)
    assert r.status_code == 200 and r.json()["state"] == "ok"


def test_sign_up_needs_a_school_from_the_list(api):
    r = api.post("/api/auth/register", {**FORM, "institution_name": "Mavjud emas maktab"})
    assert r.status_code == 422 and r.json()["code"] == "unknown_school"


def test_an_account_left_waiting_for_approval_signs_in_and_joins_its_school(app, _school):
    import json as _json

    with db_session(app) as db:
        db.add(User(email="old@maktab.uz", full_name="Eski So‘rov", role=Role.TEACHER.value,
                    password_hash=passwords.hash_password(PASSWORD), is_active=True,
                    must_change_password=False, pending_approval=True, profile=_json.dumps({"institution_name": "14-sonli maktab"})))
        db.commit()
    r = Api(TestClient(app)).login("old@maktab.uz")
    assert r.status_code == 200 and r.json()["state"] == "ok"
    assert r.json()["user"]["institution_id"] == _school


def test_sign_up_with_a_used_email_looks_the_same_but_creates_nothing(api, app):
    add_user(app, FORM["email"])
    r = api.post("/api/auth/register", FORM)
    assert r.status_code == 202 and set(r.json()) == {"registration_id", "resend_after", "message"}
    warning = app.state.ctx.mailer.outbox[-1]
    assert "urinish" in warning.subject and not any(ch.isdigit() for ch in warning.body.split("\n")[0])
    for guess in ("123456", "000000"):
        assert api.post("/api/auth/register/verify",
                        {"registration_id": r.json()["registration_id"], "code": guess}).status_code == 400


def test_sign_up_resend_has_a_cooldown_and_replaces_the_code():
    app = create_app(make_settings(code_resend_seconds=60))
    add_institution(app, "14-sonli maktab")
    api = Api(TestClient(app))
    reg_id = api.post("/api/auth/register", FORM).json()["registration_id"]
    first = last_code_for(app, FORM["email"])
    assert api.post("/api/auth/register/resend", {"registration_id": reg_id}).status_code == 429
    with db_session(app) as db:
        db.execute(update(PendingRegistration).values(last_sent_at=utcnow() - timedelta(seconds=61)))
        db.commit()
    assert api.post("/api/auth/register/resend", {"registration_id": reg_id}).status_code == 200
    second = last_code_for(app, FORM["email"])
    if first != second:
        assert api.post("/api/auth/register/verify",
                        {"registration_id": reg_id, "code": first}).status_code == 400
    assert api.post("/api/auth/register/verify",
                    {"registration_id": reg_id, "code": second}).status_code == 200


def test_sign_up_refuses_admin_roles_and_weak_passwords(api):
    assert api.post("/api/auth/register", {**FORM, "role": "SUPER_ADMIN"}).status_code == 422
    assert api.post("/api/auth/register", {**FORM, "password": "qisqa"}).status_code == 422
    assert api.post("/api/auth/register", {**FORM, "password": "Dilnoza-Kuchli-2026"}).status_code == 422


def test_expired_sign_up_code_cannot_be_used(api, app):
    reg_id = api.post("/api/auth/register", FORM).json()["registration_id"]
    code = last_code_for(app, FORM["email"])
    with db_session(app) as db:
        db.execute(update(PendingRegistration).values(expires_at=utcnow() - timedelta(seconds=1)))
        db.commit()
    r = api.post("/api/auth/register/verify", {"registration_id": reg_id, "code": code})
    assert r.status_code == 400 and r.json()["code"] == "registration_expired"


def test_an_administrator_can_block_a_sign_up_that_does_not_belong(api, app):
    reg_id = api.post("/api/auth/register", FORM).json()["registration_id"]
    api.post("/api/auth/register/verify", {"registration_id": reg_id, "code": last_code_for(app, FORM["email"])})
    admin = add_user(app, "root@maktab.uz", Role.SUPER_ADMIN, mfa=True)
    boss = Api(TestClient(app))
    boss.login("root@maktab.uz", mfa_secret=admin.mfa_secret)
    uid = next(u["id"] for u in boss.get("/api/admin/users").json() if u["email"] == FORM["email"])
    assert boss.patch(f"/api/admin/users/{uid}", {"is_active": False}).status_code == 200
    assert Api(TestClient(app)).login(FORM["email"], NEW).status_code == 401


def test_a_school_administrator_hears_about_sign_ups_that_name_their_school(api, app):
    mine = add_institution(app, "14-sonli maktab")
    other = add_institution(app, "15-sonli maktab")
    add_user(app, "dir14@maktab.uz", Role.INSTITUTION_ADMIN, mine)
    add_user(app, "dir15@maktab.uz", Role.INSTITUTION_ADMIN, other)
    reg_id = api.post("/api/auth/register", FORM).json()["registration_id"]
    code = last_code_for(app, FORM["email"])
    assert api.post("/api/auth/register/verify", {"registration_id": reg_id, "code": code}).status_code == 200
    to = {m.to for m in app.state.ctx.mailer.outbox}
    assert "dir14@maktab.uz" in to and "dir15@maktab.uz" not in to


def test_a_sign_up_rings_the_administrators_bell_in_the_app(api, app):
    from conftest import Api as _Api

    mine = add_institution(app, "14-sonli maktab")
    boss = add_user(app, "root@maktab.uz", Role.SUPER_ADMIN, mfa=True)
    add_user(app, "dir14@maktab.uz", Role.INSTITUTION_ADMIN, mine)
    add_user(app, "t@maktab.uz", Role.TEACHER, mine)
    reg_id = api.post("/api/auth/register", FORM).json()["registration_id"]
    code = last_code_for(app, FORM["email"])
    assert api.post("/api/auth/register/verify", {"registration_id": reg_id, "code": code}).status_code == 200

    def bell(email, **kw):
        a = _Api(TestClient(app))
        me = a.login(email, **kw).json()["user"]["id"]
        # The app shows the ones addressed to the person (a system administrator
        # can also read others' for oversight).
        return [n for n in a.get("/api/records").json()["items"]["notification"]
                if n["recipientUserId"] == me]

    for got in (bell("root@maktab.uz", mfa_secret=boss.mfa_secret), bell("dir14@maktab.uz")):
        assert len(got) == 1 and got[0]["type"] == "SIGNUP" and "Karimova Dilnoza" in got[0]["body"]
        assert got[0]["isRead"] is False
    assert bell("t@maktab.uz") == []  # nobody else hears about it


def test_the_sign_up_form_lists_schools_by_name_only(api, app):
    add_institution(app, "15-sonli maktab")  # "14-sonli maktab" comes from the fixture
    r = api.get("/api/auth/institutions")
    assert r.status_code == 200
    assert [x["name"] for x in r.json()] == ["14-sonli maktab", "15-sonli maktab"]
    assert all(set(x) == {"id", "name"} for x in r.json())  # nothing else leaks
