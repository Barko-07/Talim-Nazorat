from __future__ import annotations

import os
import re
import time
from dataclasses import replace

import pyotp
import pytest
from fastapi.testclient import TestClient

os.environ["INDIVID_ENV"] = "test"
os.environ.setdefault("DATABASE_URL", "sqlite://")

from app.config import load_settings  # noqa: E402
from app.main import create_app  # noqa: E402
from app.models import Institution, Role, User  # noqa: E402
from app.security import passwords  # noqa: E402

PASSWORD = "Xavfsiz-Parol-2026"

# Argon2 at full strength makes the suite slow; tests use cheap parameters.
from argon2 import PasswordHasher  # noqa: E402

passwords._hasher = PasswordHasher(time_cost=1, memory_cost=1024, parallelism=1)
passwords.DUMMY_HASH = passwords._hasher.hash("dummy-password-x")


def make_settings(**overrides):
    # Tests log in many times a second; the resend gap is tested on its own.
    overrides.setdefault("code_resend_seconds", 0)
    return replace(load_settings(), **overrides)


@pytest.fixture
def app():
    return create_app(make_settings())


@pytest.fixture
def client(app):
    return TestClient(app)


def db_session(app):
    return app.state.ctx.db.sessionmaker()


def add_institution(app, name="1-sonli maktab") -> str:
    with db_session(app) as db:
        inst = Institution(name=name)
        db.add(inst)
        db.commit()
        return inst.id


def add_user(app, email, role=Role.PSYCHOLOGIST, institution_id=None, *, mfa=False,
             must_change=False, active=True) -> User:
    with db_session(app) as db:
        u = User(email=email, full_name="Test Foydalanuvchi", role=role.value,
                 institution_id=institution_id, password_hash=passwords.hash_password(PASSWORD),
                 must_change_password=must_change, is_active=active)
        if mfa:
            u.mfa_secret = pyotp.random_base32()
            u.mfa_enabled = True
        db.add(u)
        db.commit()
        db.refresh(u)
        return u


def totp_now(secret: str, offset_steps: int = 0) -> str:
    t = pyotp.TOTP(secret)
    return t.at(time.time() + offset_steps * t.interval)


class Api:
    """Test client that behaves like the real web app: custom header + CSRF token."""

    def __init__(self, client: TestClient):
        self.c = client
        self.csrf = ""

    def _h(self, extra=None):
        h = {"X-Requested-With": "XMLHttpRequest"}
        if self.csrf:
            h["X-CSRF-Token"] = self.csrf
        h.update(extra or {})
        return h

    def get(self, url, **kw):
        return self.c.get(url, **kw)

    def post(self, url, json=None, headers=None):
        r = self.c.post(url, json=json, headers=self._h(headers))
        self._remember(r)
        return r

    def put(self, url, json=None, headers=None):
        return self.c.put(url, json=json, headers=self._h(headers))

    def patch(self, url, json=None, headers=None):
        return self.c.patch(url, json=json, headers=self._h(headers))

    def delete(self, url, headers=None):
        return self.c.delete(url, headers=self._h(headers))

    def _remember(self, r):
        try:
            body = r.json()
        except ValueError:
            return
        if isinstance(body, dict) and body.get("csrf_token"):
            self.csrf = body["csrf_token"]

    def login(self, email, password=PASSWORD, mfa_secret=None, email_code=True, remember=False):
        """Logs in like the app: password, then the second factor (authenticator
        code, or the code emailed to the account - read from the test outbox)."""
        r = self.post("/api/auth/login", {"email": email, "password": password, "remember": remember})
        if r.status_code == 200 and r.json()["state"] == "mfa_required" and mfa_secret:
            r = self.post("/api/auth/mfa/verify", {"code": totp_now(mfa_secret)})
        if r.status_code == 200 and r.json()["state"] == "email_code_required" and email_code:
            code = last_code_for(self.c.app, email)
            r = self.post("/api/auth/email-code/verify", {"code": code})
        return r


def last_code_for(app, email) -> str:
    mails = [m for m in app.state.ctx.mailer.outbox if m.to == email]
    return re.search(r"\b(\d{6})\b", mails[-1].body).group(1)


@pytest.fixture
def api(client):
    return Api(client)
