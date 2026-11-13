"""Server administration commands (run on the server, never exposed over HTTP).

    python -m app.cli init-db
    python -m app.cli create-admin --email you@example.uz --name "Ism Familiya"
    python -m app.cli reset-mfa --email you@example.uz
    python -m app.cli check-config
    python -m app.cli cleanup        (daily, from cron: expired sessions, codes, counters)
    python -m app.cli add-schools --region "Chortoq tumani" --first 1 --last 59
                                     (adds "1-sonli maktab" ... for the sign-up list;
                                      names that already exist are kept)
    python -m app.cli rotate-key     (re-encrypt everything with DATA_ENCRYPTION_KEY;
                                      see docs/handover.md for the full procedure)
"""
from __future__ import annotations

import argparse
import getpass
import os
import sys

from datetime import timedelta

from sqlalchemy import Text, delete, or_, select, type_coerce, update

from . import crypto, identity
from .config import ConfigError, load_settings
from .db import Database
from .models import Base, AuthSession, Institution, OneTimeCode, PendingRegistration, RateCounter, Role, User, utcnow
from .security import audit, passwords, sessions


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python -m app.cli")
    sub = parser.add_subparsers(dest="cmd", required=True)
    sub.add_parser("init-db", help="create tables")
    sub.add_parser("check-config", help="validate environment variables")
    sub.add_parser("cleanup", help="delete expired sessions, codes and counters")
    sub.add_parser("rotate-key", help="re-encrypt every sensitive value with the current key")
    ca = sub.add_parser("create-admin", help="create a system administrator")
    ca.add_argument("--email", required=True)
    ca.add_argument("--name", required=True)
    rm = sub.add_parser("reset-mfa", help="turn off 2FA for an account that lost its phone")
    rm.add_argument("--email", required=True)
    sc = sub.add_parser("add-schools", help="add numbered schools to the sign-up list")
    sc.add_argument("--region", required=True)
    sc.add_argument("--first", type=int, default=1)
    sc.add_argument("--last", type=int, required=True)
    args = parser.parse_args(argv)

    try:
        settings = load_settings()
    except ConfigError as exc:
        print(f"Configuration error: {exc}", file=sys.stderr)
        return 2
    if args.cmd == "check-config":
        print(f"OK: environment={settings.environment}")
        return 0

    crypto.configure(settings.data_encryption_key, settings.secret_key,
                     settings.old_data_encryption_keys)
    db_ = Database(settings.database_url)
    db_.create_all()
    if args.cmd == "init-db":
        print("Tables are ready.")
        return 0
    if args.cmd == "cleanup":
        return _cleanup(db_)
    if args.cmd == "add-schools":
        return _add_schools(db_, args.region.strip(), args.first, args.last)
    if args.cmd == "rotate-key":
        # The change history is append-only for the app's database account, so
        # this runs with the owner account when OWNER_DATABASE_URL is given.
        owner_url = os.environ.get("OWNER_DATABASE_URL", "")
        return _rotate_key(Database(owner_url) if owner_url else db_, settings)

    email = args.email.strip().lower()
    if args.cmd == "reset-mfa":
        with db_.sessionmaker() as db:
            user = identity.find_by_email(db, email)
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
        if identity.find_by_email(db, email):
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


def _add_schools(db_: Database, region: str, first: int, last: int) -> int:
    """Numbered schools ("7-sonli maktab") for the sign-up form. Idempotent:
    a school whose name is already there (any spelling of case/spaces) stays."""
    if not (1 <= first <= last <= 500):
        print("Numbers must be 1..500 and first <= last.", file=sys.stderr)
        return 1
    with db_.sessionmaker() as db:
        have = {" ".join(n.lower().split()) for n in db.scalars(select(Institution.name))}
        added = 0
        for n in range(first, last + 1):
            name = f"{n}-sonli maktab"
            if name.lower() in have:
                continue
            db.add(Institution(name=name, region=region))
            added += 1
        db.commit()
    print(f"Added {added} schools ({last - first + 1 - added} were already there).")
    return 0


def _cleanup(db_: Database) -> int:
    """Keeps the database free of dead login data. Work data and the audit
    history are never touched here."""
    import time

    now = utcnow()
    week_ago = now - timedelta(days=7)
    with db_.sessionmaker() as db:
        sessions_gone = db.execute(delete(AuthSession).where(
            or_(AuthSession.revoked.is_(True), AuthSession.last_seen_at < now - timedelta(days=31)),
            AuthSession.last_seen_at < week_ago)).rowcount
        codes_gone = db.execute(delete(OneTimeCode).where(OneTimeCode.created_at < now - timedelta(days=1))).rowcount
        regs_gone = db.execute(delete(PendingRegistration).where(
            PendingRegistration.expires_at < now - timedelta(days=1))).rowcount
        epoch = int(time.time())
        counters_gone = db.execute(delete(RateCounter).where(RateCounter.window < epoch - 25 * 3600)).rowcount
        db.commit()
        audit.record(db, "CLEANUP", detail=f"sessions={sessions_gone} codes={codes_gone} "
                                           f"registrations={regs_gone} counters={counters_gone}")
    print(f"removed: sessions={sessions_gone} codes={codes_gone} registrations={regs_gone} "
          f"counters={counters_gone}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())


def _rotate_key(db_: Database, settings) -> int:
    """Re-encrypts every encrypted column with the current key. Old keys must
    be listed in DATA_ENCRYPTION_KEY_OLD. Safe to run again: values already
    under the current key are skipped. Each table is one transaction."""
    if not settings.old_data_encryption_keys:
        print("DATA_ENCRYPTION_KEY_OLD is empty: set it to the previous key first.", file=sys.stderr)
        return 2
    total = 0
    for table in Base.metadata.sorted_tables:
        cols = [c for c in table.columns if isinstance(c.type, crypto.EncryptedText)]
        if not cols:
            continue
        pk = list(table.primary_key.columns)
        raw = [type_coerce(c, Text).label(c.name) for c in cols]
        changed = 0
        with db_.engine.begin() as conn:
            for row in conn.execute(select(*pk, *raw)).mappings().all():
                values = {}
                for c in cols:
                    stored = row[c.name]
                    if stored is None or crypto.is_current(stored, c.type.context):
                        continue
                    # decrypt() raises if no known key opens it: nothing is half-changed.
                    values[c.name] = crypto.encrypt(crypto.decrypt(stored, c.type.context), c.type.context)
                if values:
                    where = [k == row[k.name] for k in pk]
                    conn.execute(update(table).where(*where).values(
                        {table.c[n]: type_coerce(v, Text) for n, v in values.items()}))
                    changed += 1
        print(f"{table.name}: {changed} rows re-encrypted")
        total += changed
    with db_.sessionmaker() as db:
        audit.record(db, "DATA_KEY_ROTATED", severity="warning", detail=f"rows={total}",
                     webhook_url=settings.alert_webhook_url)
    print(f"Done: {total} rows. Remove DATA_ENCRYPTION_KEY_OLD and restart the service.")
    return 0
