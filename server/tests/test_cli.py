from sqlalchemy import select

from app import cli
from app.db import Database
from app.models import User


def test_create_admin_and_reset_mfa(monkeypatch, tmp_path):
    url = f"sqlite:///{tmp_path / 'cli.db'}"
    monkeypatch.setenv("DATABASE_URL", url)
    answers = iter(["Kuchli-Tog-Yoli-2026", "Kuchli-Tog-Yoli-2026"])
    monkeypatch.setattr(cli.getpass, "getpass", lambda prompt="": next(answers))
    assert cli.main(["create-admin", "--email", "Owner@Individ.uz", "--name", "Ega Admin"]) == 0

    db = Database(url).sessionmaker()
    u = db.scalar(select(User).where(User.email == "owner@individ.uz"))
    assert u.role == "SUPER_ADMIN" and u.password_hash.startswith("$argon2id$")
    u.mfa_enabled = True
    db.commit()
    db.close()

    assert cli.main(["reset-mfa", "--email", "owner@individ.uz"]) == 0
    db = Database(url).sessionmaker()
    assert db.scalar(select(User).where(User.email == "owner@individ.uz")).mfa_enabled is False
    db.close()


def test_create_admin_rejects_weak_password(monkeypatch, tmp_path):
    monkeypatch.setenv("DATABASE_URL", f"sqlite:///{tmp_path / 'w.db'}")
    monkeypatch.setattr(cli.getpass, "getpass", lambda prompt="": "Parol2026!")
    assert cli.main(["create-admin", "--email", "a@b.uz", "--name", "Ab Cd"]) == 1


def test_rotate_key_reencrypts_everything_and_old_key_then_fails(monkeypatch, tmp_path):
    import base64
    import os

    import pytest
    from cryptography.exceptions import InvalidTag
    from sqlalchemy import Text, type_coerce

    from app import crypto
    from app.models import Record, RecordChange

    def b64(k):
        return base64.urlsafe_b64encode(k).decode()

    old, new = os.urandom(32), os.urandom(32)
    url = f"sqlite:///{tmp_path / 'rot.db'}"
    monkeypatch.setenv("DATABASE_URL", url)

    # Data written under the old key, including the append-only history.
    crypto.configure(old, "s")
    db_ = Database(url)
    db_.create_all()
    with db_.sessionmaker() as db:
        u = User(email="a@b.uz", full_name="A B", role="TEACHER", password_hash="x",
                 profile='{"phone":"+998"}')
        db.add(u)
        db.flush()
        db.add(Record(kind="student", rid="s1", owner_id=u.id, data='{"name":"Dilnoza"}'))
        db.add(RecordChange(user_id=u.id, kind="student", rid="s1", action="create",
                            after='{"name":"Dilnoza"}'))
        db.commit()

    # Without the old key listed the command refuses to start.
    monkeypatch.setenv("DATA_ENCRYPTION_KEY", b64(new))
    monkeypatch.delenv("DATA_ENCRYPTION_KEY_OLD", raising=False)
    assert cli.main(["rotate-key"]) == 2

    monkeypatch.setenv("DATA_ENCRYPTION_KEY_OLD", b64(old))
    assert cli.main(["rotate-key"]) == 0
    assert cli.main(["rotate-key"]) == 0  # second run has nothing left to do

    # Every value now opens with the new key alone; the old key opens nothing.
    crypto.configure(new, "s")
    with db_.sessionmaker() as db:
        assert db.scalar(select(Record.data)) == '{"name":"Dilnoza"}'
        assert db.scalar(select(RecordChange.after)) == '{"name":"Dilnoza"}'
        assert db.scalar(select(User.profile)) == '{"phone":"+998"}'
        raw = db.scalar(select(type_coerce(Record.data, Text)))
    crypto.configure(old, "s")
    with pytest.raises(InvalidTag):
        crypto.decrypt(raw, "records.data")
