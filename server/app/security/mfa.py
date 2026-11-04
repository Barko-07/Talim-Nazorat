"""Two-factor authentication with TOTP (Google Authenticator, Microsoft
Authenticator, etc.). Codes cannot be replayed: the last accepted time step
is stored per user."""
from __future__ import annotations

import secrets
import time

import pyotp

ISSUER = "Individ"


def new_secret() -> str:
    return pyotp.random_base32()


def provisioning_uri(secret: str, email: str) -> str:
    return pyotp.TOTP(secret).provisioning_uri(name=email, issuer_name=ISSUER)


# No 0/O, 1/I/L: the codes are copied by hand from paper.
_RECOVERY_ALPHABET = "23456789ABCDEFGHJKMNPQRSTUVWXYZ"
RECOVERY_CODE_COUNT = 10


def new_recovery_codes() -> list[str]:
    def one() -> str:
        raw = "".join(secrets.choice(_RECOVERY_ALPHABET) for _ in range(8))
        return f"{raw[:4]}-{raw[4:]}"

    return [one() for _ in range(RECOVERY_CODE_COUNT)]


def normalize_recovery_code(code: str) -> str:
    return code.strip().upper().replace("-", "")


def verify(secret: str, code: str, last_step: int) -> int | None:
    """Returns the accepted time step, or None. Allows ±1 step clock drift."""
    code = (code or "").strip().replace(" ", "")
    if not (code.isdigit() and len(code) == 6):
        return None
    totp = pyotp.TOTP(secret)
    now_step = int(time.time() // totp.interval)
    for step in (now_step - 1, now_step, now_step + 1):
        if step <= last_step:
            continue  # already used: replay
        if pyotp.utils.strings_equal(totp.generate_otp(step), code):
            return step
    return None
