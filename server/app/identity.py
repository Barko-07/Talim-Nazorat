"""One person, one account. Two spellings of the same mailbox or phone number
must not become two accounts.

- Email: case does not matter anywhere; for Gmail, dots and a "+tag" in the
  name do not matter either (mistaker.0908+x@gmail.com is mistaker0908@gmail.com).
- Phone: only the digits count, and only the last nine (the Uzbek subscriber
  number), so "+998 90 111-22-33", "998901112233" and "90 111 22 33" are one.
"""
from __future__ import annotations

import re

_GMAIL = {"gmail.com", "googlemail.com"}


def email_key(email: str) -> str:
    email = (email or "").strip().lower()
    name, at, domain = email.rpartition("@")
    if not at:
        return email
    if domain in _GMAIL:
        name = name.split("+", 1)[0].replace(".", "")
        domain = "gmail.com"
    return f"{name}@{domain}"


def phone_key(phone: str | None) -> str | None:
    digits = re.sub(r"\D", "", phone or "")
    return digits[-9:] if len(digits) >= 9 else None


def find_by_email(db, email: str):
    """The account for this mailbox, however the address is spelled."""
    from sqlalchemy import select

    from .models import User
    return db.scalar(select(User).where(User.email_key == email_key(email)))


def phone_taken(db, phone: str | None, except_user_id: str | None = None) -> bool:
    from sqlalchemy import select

    from .models import User
    key = phone_key(phone)
    if key is None:
        return False
    stmt = select(User.id).where(User.phone_key == key)
    if except_user_id:
        stmt = stmt.where(User.id != except_user_id)
    return db.scalar(stmt.limit(1)) is not None
