import re
from datetime import timedelta

from sqlalchemy import select

from app.models import OneTimeCode, User, utcnow

from conftest import PASSWORD, Api, add_user, db_session

NEW = "Yangi-Mustahkam-Parol-77"


def _last_code(app) -> str:
    mail = app.state.ctx.mailer.outbox[-1]
    return re.search(r"\b(\d{6})\b", mail.body).group(1)


def test_reset_request_does_not_reveal_accounts(api, app):
    add_user(app, "real@maktab.uz")
    a = api.post("/api/auth/password/reset/request", {"email": "real@maktab.uz"})
    b = api.post("/api/auth/password/reset/request", {"email": "ghost@maktab.uz"})
    assert a.status_code == b.status_code == 202
    assert a.json() == b.json()
    assert len(app.state.ctx.mailer.outbox) == 1  # only the real account gets mail


def test_reset_with_code_works_once_and_signs_out_everywhere(api, app, client):
    add_user(app, "r@maktab.uz")
    other = Api(type(client)(app))
    other.login("r@maktab.uz")
    assert other.get("/api/auth/me").status_code == 200

    api.post("/api/auth/password/reset/request", {"email": "r@maktab.uz"})
    code = _last_code(app)
    with db_session(app) as db:
        stored = db.scalars(select(OneTimeCode)).one()
        assert code not in stored.code_hash  # stored hashed
    ok = api.post("/api/auth/password/reset/confirm", {"email": "r@maktab.uz", "code": code, "new_password": NEW})
    assert ok.status_code == 200
    again = api.post("/api/auth/password/reset/confirm", {"email": "r@maktab.uz", "code": code, "new_password": NEW + "x"})
    assert again.status_code == 400  # single use
    assert other.get("/api/auth/me").status_code == 401  # old sessions revoked
    assert api.login("r@maktab.uz", NEW).status_code == 200
    assert "parol tiklandi" in app.state.ctx.mailer.outbox[-1].subject


def test_reset_code_expires(api, app):
    add_user(app, "exp@maktab.uz")
    api.post("/api/auth/password/reset/request", {"email": "exp@maktab.uz"})
    code = _last_code(app)
    with db_session(app) as db:
        db.scalars(select(OneTimeCode)).one().expires_at = utcnow() - timedelta(seconds=1)
        db.commit()
    r = api.post("/api/auth/password/reset/confirm", {"email": "exp@maktab.uz", "code": code, "new_password": NEW})
    assert r.status_code == 400


def test_reset_code_attempts_are_limited(api, app):
    add_user(app, "att@maktab.uz")
    api.post("/api/auth/password/reset/request", {"email": "att@maktab.uz"})
    code = _last_code(app)
    wrong = "000000" if code != "000000" else "111111"
    for _ in range(5):
        api.post("/api/auth/password/reset/confirm", {"email": "att@maktab.uz", "code": wrong, "new_password": NEW})
    r = api.post("/api/auth/password/reset/confirm", {"email": "att@maktab.uz", "code": code, "new_password": NEW})
    assert r.status_code == 400  # burned after too many wrong guesses


def test_new_code_invalidates_previous_one(api, app):
    add_user(app, "two@maktab.uz")
    api.post("/api/auth/password/reset/request", {"email": "two@maktab.uz"})
    first = _last_code(app)
    api.post("/api/auth/password/reset/request", {"email": "two@maktab.uz"})
    second = _last_code(app)
    if first != second:
        r = api.post("/api/auth/password/reset/confirm", {"email": "two@maktab.uz", "code": first, "new_password": NEW})
        assert r.status_code == 400


def test_weak_passwords_rejected(api, app):
    add_user(app, "weak@maktab.uz")
    for weak in ["short", "alllowercaseletters", "Parol2026!", "weak@maktab.uz-Pass1"]:
        api.post("/api/auth/password/reset/request", {"email": "weak@maktab.uz"})
        code = _last_code(app)
        r = api.post("/api/auth/password/reset/confirm",
                     {"email": "weak@maktab.uz", "code": code, "new_password": weak})
        assert r.status_code in (400, 422), weak


def test_change_password_needs_current_password_and_emailed_code(api, app):
    add_user(app, "ch@maktab.uz")
    api.login("ch@maktab.uz")
    assert api.post("/api/auth/password/change/request").status_code == 200
    code = _last_code(app)
    bad = api.post("/api/auth/password/change", {"current_password": "Notogri-Parol-1", "code": code, "new_password": NEW})
    assert bad.status_code == 401
    ok = api.post("/api/auth/password/change", {"current_password": PASSWORD, "code": code, "new_password": NEW})
    assert ok.status_code == 200
    with db_session(app) as db:
        u = db.scalar(select(User).where(User.email == "ch@maktab.uz"))
        assert u.must_change_password is False


def test_code_requests_are_rate_limited(api, app):
    add_user(app, "spam@maktab.uz")
    api.login("spam@maktab.uz")
    codes = [api.post("/api/auth/password/change/request").status_code for _ in range(5)]
    assert 429 in codes
