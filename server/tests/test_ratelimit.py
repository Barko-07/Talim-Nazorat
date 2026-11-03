from sqlalchemy import func, select

from app.models import AuditEvent
from app.security import ratelimit

from conftest import db_session


def test_cleanup_never_resets_longer_windows(app, monkeypatch):
    monkeypatch.setattr(ratelimit.random, "random", lambda: 0.0)  # clean up on every hit
    lim = app.state.ctx.db_limiter
    with db_session(app) as db:
        for _ in range(3):
            assert lim.hit(db, "reset-user:u1", 3, 3600)
        for i in range(5):
            lim.hit(db, f"login-ip:10.0.0.{i}", 10, 60)
        assert lim.hit(db, "reset-user:u1", 3, 3600) is False  # still counted


def test_flood_of_rejected_requests_is_not_a_flood_of_audit_rows(client, app):
    for _ in range(50):
        client.post("/api/auth/login", json={})  # no custom header -> rejected
    with db_session(app) as db:
        n = db.scalar(select(func.count()).select_from(AuditEvent).where(AuditEvent.action == "CSRF_REJECTED"))
    assert n <= 5
