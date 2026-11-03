import logging

import pytest
from sqlalchemy import select

from app.config import ConfigError, Settings, load_settings, production_problems
from app.models import AuditEvent
from app.security import audit

from conftest import add_user, db_session


def test_burst_of_failures_raises_suspicious_activity_alert(api, app):
    add_user(app, "v@maktab.uz")
    for i in range(10):
        api.login(f"user{i}@maktab.uz", "Notogri-Parol-1")
    with db_session(app) as db:
        alerts = list(db.scalars(select(AuditEvent).where(AuditEvent.action == "SUSPICIOUS_ACTIVITY")))
    assert len(alerts) == 1 and alerts[0].severity == "alert"


def test_logs_mask_logins_and_never_contain_passwords(api, app, caplog):
    caplog.set_level(logging.INFO, logger="individ.security")
    api.login("secretuser@maktab.uz", "Juda-Maxfiy-Parol-9")
    text = caplog.text
    assert "secretuser@maktab.uz" not in text and "se***@maktab.uz" in text
    assert "Juda-Maxfiy-Parol-9" not in text


def test_log_injection_control_characters_removed(app):
    with db_session(app) as db:
        audit.record(db, "TEST", subject="a\nFAKE LOG LINE\r", detail="x\x00y")
        e = db.scalar(select(AuditEvent).where(AuditEvent.action == "TEST"))
    assert "\n" not in e.subject and "\r" not in e.subject and "\x00" not in e.detail


def test_mask_login():
    assert audit.mask_login("sarvar@talim.uz") == "sa***@talim.uz"
    assert audit.mask_login("+998 90 123-45-67") == "***4567"


GOOD = dict(
    INDIVID_ENV="production",
    SECRET_KEY="k" * 64,
    DATA_ENCRYPTION_KEY="QUJDREVGR0hJSktMTU5PUFFSU1RVVldYWVphYmNkZWY=",
    DATABASE_URL="postgresql+psycopg://individ@127.0.0.1/individ",
    PUBLIC_BASE_URL="https://individ.uz",
    ALLOWED_ORIGINS="https://individ.uz",
    SMTP_HOST="smtp.example.uz",
    SMTP_FROM="noreply@individ.uz",
)


def _env(monkeypatch, **kw):
    for k in list(GOOD) + ["COOKIE_SECURE"]:
        monkeypatch.delenv(k, raising=False)
    for k, v in {**GOOD, **kw}.items():
        if v is not None:
            monkeypatch.setenv(k, v)


def test_good_production_config_loads(monkeypatch):
    _env(monkeypatch)
    assert load_settings().is_production


@pytest.mark.parametrize("override", [
    {"SECRET_KEY": None},
    {"SECRET_KEY": "short"},
    {"DATA_ENCRYPTION_KEY": None},
    {"DATABASE_URL": "sqlite:///x.db"},
    {"PUBLIC_BASE_URL": "http://individ.uz"},
    {"ALLOWED_ORIGINS": "*"},
    {"COOKIE_SECURE": "false"},
    {"SMTP_HOST": None},
])
def test_unsafe_production_config_refuses_to_start(monkeypatch, override):
    _env(monkeypatch, **override)
    with pytest.raises(ConfigError):
        load_settings()
