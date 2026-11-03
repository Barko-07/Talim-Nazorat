"""Server administration commands (run on the server, never exposed over HTTP).

    python -m app.cli init-db
    python -m app.cli create-admin --email you@example.uz --name "Ism Familiya"
    python -m app.cli reset-mfa --email you@example.uz
    python -m app.cli check-config
"""
from __future__ import annotations

import argparse
import getpass
import sys

from sqlalchemy import select

from . import crypto
from .config import ConfigError, load_settings
from .db import Database
from .models import Role, User
from .security import audit, passwords, sessions


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python -m app.cli")
    sub = parser.add_subparsers(dest="cmd", required=True)
    sub.add_parser("init-db", help="create tables")
    sub.add_parser("check-config", help="validate environment variables")
    ca = sub.add_parser("create-admin", help="create a system administrator")
    ca.add_argument("--email", required=True)
    ca.add_argument("--name", required=True)
    rm = sub.add_parser("reset-mfa", help="turn off 2FA for an account that lost its phone")
    rm.add_argument("--email", required=True)
    args = parser.parse_args(argv)

    try:
        settings = load_settings()
    except ConfigError as exc:
        print(f"Configuration error: {exc}", file=sys.stderr)
        return 2
    if args.cmd == "check-config":
        print(f"OK: environment={settings.environment}")
        return 0

    crypto.configure(settings.data_encryption_key, settings.secret_key)
    db_ = Database(settings.database_url)
    db_.create_all()
    if args.cmd == "init-db":
        print("Tables are ready.")
        return 0

    email = args.email.strip().lower()
    if args.cmd == "reset-mfa":
        with db_.sessionmaker() as db:
            user = db.scalar(select(User).where(User.email == email))
            if user is None:
                print("No such account.", file=sys.stderr)
                return 1
            user.mfa_enabled = False
            user.mfa_secret = None
            db.commit()
            sessions.revoke_all(db, user.id)
            audit.record(db, "MFA_RESET_BY_CLI", severity="alert", user_id=user.id,
                         subject=audit.mask_login(email), webhook_url=settings.alert_webhook_url)
        print("2FA turned off and all sessions closed. It must be set up again at next login.")
        return 0

    with db_.sessionmaker() as db:
        if db.scalar(select(User).where(User.email == email)):
            print("An account with this email already exists.", file=sys.stderr)
            return 1
        # Typed twice, never shown, never stored in plain text or shell history.
        pw = getpass.getpass("New administrator password: ")
        if pw != getpass.getpass("Repeat password: "):
            print("Passwords do not match.", file=sys.stderr)
            return 1
        problems = passwords.password_problems(pw, email=email, full_name=args.name)
        if problems:
            print("Weak password:\n- " + "\n- ".join(problems), file=sys.stderr)
            return 1
        user = User(email=email, full_name=args.name.strip()[:120], role=Role.SUPER_ADMIN.value,
                    password_hash=passwords.hash_password(pw), must_change_password=False)
        db.add(user)
        db.commit()
        audit.record(db, "ADMIN_CREATED_BY_CLI", severity="warning", user_id=user.id,
                     subject=audit.mask_login(email))
    print("Administrator created. Two-factor authentication must be set up at first login.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
