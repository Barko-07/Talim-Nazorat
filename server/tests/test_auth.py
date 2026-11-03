from datetime import timedelta

from sqlalchemy import select

from app.models import AuditEvent, AuthSession, Role, User, utcnow
from app.security import passwords

from conftest import PASSWORD, Api, add_institution, add_user, db_session, totp_now


def test_login_sets_httponly_strict_cookie_and_returns_csrf(api, app):
    add_user(app, "psy@maktab.uz")
    r = api.login("psy@maktab.uz")
    assert r.status_code == 200
    assert r.json()["state"] == "ok"
    assert r.json()["csrf_token"]
    cookie = r.headers["set-cookie"].lower()
    assert "httponly" in cookie and "samesite=strict" in cookie and "path=/" in cookie
    assert "password" not in r.text.lower()


def test_secure_cookie_uses_host_prefix_when_secure():
    from conftest import make_settings
    from app.main import create_app
    from fastapi.testclient import TestClient

    app = create_app(make_settings(cookie_secure=True))
    add_user(app, "a@maktab.uz")
    api = Api(TestClient(app, base_url="https://testserver"))
    r = api.login("a@maktab.uz")
    cookie = r.headers["set-cookie"]
    assert cookie.startswith("__Host-individ_session=")
    assert "Secure" in cookie and "HttpOnly" in cookie


def test_unknown_and_wrong_password_give_same_answer(api, app):
    add_user(app, "real@maktab.uz")
    a = api.login("real@maktab.uz", "Notogri-Parol-1")
    b = api.login("nobody@maktab.uz", "Notogri-Parol-1")
    assert a.status_code == b.status_code == 401
    assert a.json() == b.json()


def test_lockout_after_repeated_failures_blocks_even_correct_password(api, app):
    add_user(app, "lock@maktab.uz")
    for _ in range(5):
        assert api.login("lock@maktab.uz", "Notogri-Parol-1").status_code == 401
    assert api.login("lock@maktab.uz").status_code == 401  # correct password, still locked
    with db_session(app) as db:
        actions = [e.action for e in db.scalars(select(AuditEvent))]
    assert "ACCOUNT_LOCKED" in actions and "LOGIN_WHILE_LOCKED" in actions


def test_login_rate_limited_per_ip(api, app):
    codes = [api.login(f"x{i}@maktab.uz", "Notogri-Parol-1").status_code for i in range(12)]
    assert 429 in codes


def test_passwords_stored_as_argon2id(app):
    u = add_user(app, "hash@maktab.uz")
    assert u.password_hash.startswith("$argon2id$")
    assert PASSWORD not in u.password_hash


def test_legacy_flutter_pbkdf2_hash_accepted_then_upgraded(api, app):
    import base64, hashlib, os

    salt = os.urandom(16)
    key = hashlib.pbkdf2_hmac("sha256", PASSWORD.encode(), salt, 20000, 32)
    legacy = f"pbkdf2$20000${base64.b64encode(salt).decode()}${base64.b64encode(key).decode()}"
    u = add_user(app, "old@maktab.uz")
    with db_session(app) as db:
        db.get(User, u.id).password_hash = legacy
        db.commit()
    assert api.login("old@maktab.uz").status_code == 200
    with db_session(app) as db:
        assert db.get(User, u.id).password_hash.startswith("$argon2id$")


def test_session_rotates_on_login_and_logout_revokes(api, app, client):
    add_user(app, "rot@maktab.uz")
    client.cookies.set("individ_session", "attacker-chosen-token")
    r = api.login("rot@maktab.uz")
    token = r.headers["set-cookie"].split(";")[0].split("=", 1)[1]
    assert token and token != "attacker-chosen-token"
    client.cookies.clear()
    client.cookies.set("individ_session", token)
    assert api.get("/api/auth/me").status_code == 200
    api.post("/api/auth/logout")
    client.cookies.clear()
    client.cookies.set("individ_session", token)  # replay the old cookie
    assert api.get("/api/auth/me").status_code == 401


def test_idle_and_absolute_timeouts(api, app):
    add_user(app, "idle@maktab.uz")
    api.login("idle@maktab.uz")
    with db_session(app) as db:
        s = db.scalars(select(AuthSession)).one()
        s.last_seen_at = utcnow() - timedelta(minutes=31)
        db.commit()
    assert api.get("/api/auth/me").status_code == 401

    api.login("idle@maktab.uz")
    with db_session(app) as db:
        s = db.scalars(select(AuthSession).where(AuthSession.revoked.is_(False))).one()
        s.created_at = utcnow() - timedelta(hours=9)
        db.commit()
    assert api.get("/api/auth/me").status_code == 401


def test_blocked_user_cannot_login_and_loses_live_session(api, app):
    u = add_user(app, "blk@maktab.uz")
    api.login("blk@maktab.uz")
    with db_session(app) as db:
        db.get(User, u.id).is_active = False
        db.commit()
    assert api.get("/api/auth/me").status_code == 401
    assert api.login("blk@maktab.uz").status_code == 401


def test_admin_must_set_up_2fa_before_anything_else(api, app):
    add_user(app, "boss@maktab.uz", Role.SUPER_ADMIN)
    r = api.login("boss@maktab.uz")
    assert r.json()["state"] == "mfa_setup_required"
    assert api.get("/api/students").status_code == 403
    assert api.get("/api/admin/users").status_code == 403

    setup = api.post("/api/auth/mfa/setup", {"password": PASSWORD})
    assert setup.status_code == 200
    secret = setup.json()["secret"]
    assert api.post("/api/auth/mfa/enable", {"code": "000000"}).status_code == 401
    r = api.post("/api/auth/mfa/enable", {"code": totp_now(secret)})
    assert r.status_code == 200 and r.json()["state"] == "ok"
    assert api.get("/api/admin/users").status_code == 200


def test_mfa_required_at_login_and_codes_cannot_be_replayed(api, app, client):
    u = add_user(app, "mfa@maktab.uz", mfa=True)
    r = api.login("mfa@maktab.uz")
    assert r.json()["state"] == "mfa_required"
    assert api.get("/api/students").status_code == 403
    code = totp_now(u.mfa_secret)
    assert api.post("/api/auth/mfa/verify", {"code": code}).status_code == 200
    api.post("/api/auth/logout")
    api.login("mfa@maktab.uz")
    assert api.post("/api/auth/mfa/verify", {"code": code}).status_code == 401  # replay


def test_mfa_verify_brute_force_limited(api, app):
    add_user(app, "mfab@maktab.uz", mfa=True)
    api.login("mfab@maktab.uz")
    codes = [api.post("/api/auth/mfa/verify", {"code": f"{i:06d}"}).status_code for i in range(7)]
    assert codes[-1] == 429


def test_temporary_password_forces_change_first(api, app):
    add_user(app, "new@maktab.uz", must_change=True)
    assert api.login("new@maktab.uz").json()["state"] == "password_change_required"
    assert api.get("/api/students").status_code == 403


def test_inst_admin_requires_mfa_by_default(api, app):
    inst = add_institution(app)
    add_user(app, "dir@maktab.uz", Role.INSTITUTION_ADMIN, inst)
    assert api.login("dir@maktab.uz").json()["state"] == "mfa_setup_required"
