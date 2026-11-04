"""Password hashing (Argon2id) and password policy."""
from __future__ import annotations

import base64
import hashlib
import hmac
import re
import secrets

from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerificationError, VerifyMismatchError

# OWASP-recommended Argon2id parameters (64 MiB, 3 passes).
_hasher = PasswordHasher(time_cost=3, memory_cost=64 * 1024, parallelism=2)

# Hash of a random password: used when the account does not exist so that
# "unknown user" and "wrong password" take the same time.
DUMMY_HASH = _hasher.hash(secrets.token_urlsafe(24))

MIN_LENGTH = 12
MAX_LENGTH = 128

# Small built-in list; extend with a larger breached-password list on the server.
_COMMON = {
    "password", "password1", "password123", "qwerty123", "123456789012",
    "admin123", "adminpass123!", "parol2026!", "parol123", "letmein123",
    "iloveyou123", "welcome123", "uzbekistan123", "toshkent123",
}


def hash_password(password: str) -> str:
    return _hasher.hash(password)


def verify_password(password: str, stored: str) -> bool:
    if stored.startswith("pbkdf2$"):
        return _verify_legacy_pbkdf2(password, stored)
    try:
        return _hasher.verify(stored, password)
    except (VerifyMismatchError, VerificationError, InvalidHashError):
        return False


def needs_rehash(stored: str) -> bool:
    if stored.startswith("pbkdf2$"):
        return True
    try:
        return _hasher.check_needs_rehash(stored)
    except InvalidHashError:
        return True


def _verify_legacy_pbkdf2(password: str, stored: str) -> bool:
    """Accepts hashes made by the Flutter app (PasswordHasher) during migration;
    they are upgraded to Argon2id on the next successful login."""
    parts = stored.split("$")
    if len(parts) != 4:
        return False
    try:
        iterations = int(parts[1])
        salt = base64.b64decode(parts[2])
        expected = base64.b64decode(parts[3])
    except ValueError:
        return False
    if iterations < 1000:
        return False
    actual = hashlib.pbkdf2_hmac("sha256", password.encode(), salt, iterations, len(expected))
    return hmac.compare_digest(actual, expected)


def password_problems(password: str, *, email: str = "", full_name: str = "") -> list[str]:
    """Returns human-readable (Uzbek) reasons the password is too weak."""
    p: list[str] = []
    if len(password) < MIN_LENGTH:
        p.append(f"Parol kamida {MIN_LENGTH} belgidan iborat bo‘lsin")
    if len(password) > MAX_LENGTH:
        p.append(f"Parol {MAX_LENGTH} belgidan oshmasin")
    classes = sum(
        [
            any(c.islower() for c in password),
            any(c.isupper() for c in password),
            any(c.isdigit() for c in password),
            any(not c.isalnum() for c in password),
        ]
    )
    if classes < 3:
        p.append("Kichik va katta harf, raqam va belgilardan kamida uchtasini ishlating")
    lowered = password.lower()
    if lowered in _COMMON:
        p.append("Bu parol juda keng tarqalgan")
    # The whole login and each word-like part of it (mistaker0908 -> mistaker,
    # 0908), so a guessable fragment of the email can't be the password's core.
    local = email.split("@")[0].lower()
    parts = {local, *re.findall(r"[^\W\d_]+|\d+", local)}
    if any(len(part) >= 4 and part in lowered for part in parts):
        p.append("Parolda login (email) bo‘lmasin")
    for part in full_name.lower().split():
        if len(part) >= 4 and part in lowered:
            p.append("Parolda ismingiz bo‘lmasin")
            break
    return p


def generate_temporary_password() -> str:
    """Strong one-time password for accounts created by an admin."""
    alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789"
    while True:
        pw = "".join(secrets.choice(alphabet) for _ in range(14)) + "-" + secrets.choice("!@#%*")
        if not password_problems(pw):
            return pw
