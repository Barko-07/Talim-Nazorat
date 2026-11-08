"""One person, one account: the same mailbox or phone number, however it is
written, never becomes a second account."""
from fastapi.testclient import TestClient
from sqlalchemy import select

from app.identity import email_key, phone_key
from app.models import Role, User

from conftest import PASSWORD, Api, add_institution, add_user, db_session, last_code_for

FORM = {
    "first_name": "Dilnoza", "last_name": "Karimova", "email": "new.person@maktab.uz",
    "phone": "+998 90 111-22-33", "role": "TEACHER", "institution_name": "14-sonli maktab",
    "password": "Yangi-Mustahkam-Parol-77",
}


def test_spellings_of_one_mailbox_and_number_are_one_key():
    assert email_key("Mistaker.0908+test@GMAIL.com") == "mistaker0908@gmail.com"
    assert email_key("mistaker0908@googlemail.com") == "mistaker0908@gmail.com"
    assert email_key("A.B@maktab.uz") == "a.b@maktab.uz"  # dots matter outside Gmail
    assert phone_key("+998 90 111-22-33") == phone_key("998901112233") == phone_key("90 111 22 33")
    assert phone_key("123") is None


def test_a_gmail_alias_cannot_open_a_second_account(app):
    add_user(app, "mistaker0908@gmail.com", Role.TEACHER)
    api = Api(TestClient(app))
    r = api.post("/api/auth/register", {**FORM, "email": "Mistaker.0908+new@gmail.com"})
    assert r.status_code == 202  # same answer as always: the form does not reveal accounts
    # No code to the alias; the real owner is warned instead.
    assert [m.to for m in app.state.ctx.mailer.outbox] == ["mistaker0908@gmail.com"]
    reg_id = r.json()["registration_id"]
    for code in ("000000", "111111"):
        assert api.post("/api/auth/register/verify", {"registration_id": reg_id, "code": code}).status_code == 400
    with db_session(app) as db:
        assert len(db.scalars(select(User)).all()) == 1


def test_the_owner_signs_in_whichever_way_they_write_the_address(app):
    add_user(app, "mistaker0908@gmail.com", Role.TEACHER)
    api = Api(TestClient(app))
    r = api.post("/api/auth/login", {"email": "Mistaker.0908@gmail.com", "password": PASSWORD})
    assert r.status_code == 200 and r.json()["state"] == "email_code_required"


def test_a_phone_number_already_in_use_is_refused_everywhere(app):
    inst = add_institution(app)
    owner = add_user(app, "owner@maktab.uz", Role.TEACHER, inst)
    with db_session(app) as db:
        db.get(User, owner.id).phone = "+998901112233"
        db.commit()
    with db_session(app) as db:  # the key follows the phone
        assert db.get(User, owner.id).phone_key == "901112233"
    api = Api(TestClient(app))
    # Sign-up with the same number written differently.
    r = api.post("/api/auth/register", {**FORM, "phone": "90 111 22 33"})
    assert r.status_code == 409 and r.json()["code"] == "phone_taken"
    # Someone else changing their profile to it.
    add_user(app, "other@maktab.uz", Role.TEACHER, inst)
    other = Api(TestClient(app))
    other.login("other@maktab.uz")
    assert other.patch("/api/auth/profile", {"phone": "998 90 111-22-33"}).status_code == 409
    # Keeping one's own number is fine.
    me = Api(TestClient(app))
    me.login("owner@maktab.uz")
    assert me.patch("/api/auth/profile", {"phone": "+998 90 111 22 33"}).status_code == 200
