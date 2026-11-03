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
