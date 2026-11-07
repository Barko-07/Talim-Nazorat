"""Field-level encryption (AES-256-GCM) for sensitive columns.

Diagnoses and psychological notes are encrypted before they reach the
database, so a leaked dump or backup alone does not expose them.
"""
from __future__ import annotations

import base64
import hashlib
import hmac
import os

from cryptography.exceptions import InvalidTag
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from sqlalchemy import Text
from sqlalchemy.types import TypeDecorator

_PREFIX = "enc1:"  # legacy: no associated data
_PREFIX2 = "enc2:"  # bound to its column: a value copied into another column fails to decrypt
_key: bytes | None = None
_old_keys: tuple[bytes, ...] = ()  # only during a key change: still readable, never written
_hmac_key: bytes = b""


def configure(data_key: bytes, secret_key: str, old_keys: tuple[bytes, ...] = ()) -> None:
    global _key, _old_keys, _hmac_key
    _key = data_key
    _old_keys = tuple(k for k in old_keys if k and k != data_key)
    _hmac_key = secret_key.encode()


def encrypt(plain: str, context: str = "") -> str:
    if _key is None:
        raise RuntimeError("encryption key not configured")
    nonce = os.urandom(12)
    if not context:
        ct = AESGCM(_key).encrypt(nonce, plain.encode(), None)
        return _PREFIX + base64.urlsafe_b64encode(nonce + ct).decode()
    ct = AESGCM(_key).encrypt(nonce, plain.encode(), context.encode())
    return _PREFIX2 + base64.urlsafe_b64encode(nonce + ct).decode()


def _open(stored: str, context: str, key: bytes) -> str:
    if stored.startswith(_PREFIX2):
        raw = base64.urlsafe_b64decode(stored[len(_PREFIX2):])
        return AESGCM(key).decrypt(raw[:12], raw[12:], context.encode()).decode()
    if not stored.startswith(_PREFIX):
        raise ValueError("value is not encrypted")
    raw = base64.urlsafe_b64decode(stored[len(_PREFIX):])
    return AESGCM(key).decrypt(raw[:12], raw[12:], None).decode()


def decrypt(stored: str, context: str = "") -> str:
    if _key is None:
        raise RuntimeError("encryption key not configured")
    try:
        return _open(stored, context, _key)
    except InvalidTag:
        for old in _old_keys:
            try:
                return _open(stored, context, old)
            except InvalidTag:
                continue
        raise


def is_current(stored: str, context: str = "") -> bool:
    """True when the value is already sealed with the current key in the
    current format, so a key change can skip it."""
    if _key is None:
        raise RuntimeError("encryption key not configured")
    if context and not stored.startswith(_PREFIX2):
        return False
    try:
        _open(stored, context, _key)
        return True
    except InvalidTag:
        return False


def keyed_hash(value: str) -> str:
    """HMAC-SHA256 for tokens and codes stored in the DB (never the raw value)."""
    return hmac.new(_hmac_key, value.encode(), hashlib.sha256).hexdigest()


def constant_time_equals(a: str, b: str) -> bool:
    return hmac.compare_digest(a.encode(), b.encode())


class EncryptedText(TypeDecorator):
    """`context` names the column ("table.column"); it is authenticated with
    every value, so ciphertext moved between columns is rejected."""

    impl = Text
    cache_ok = True

    def __init__(self, context: str = "", *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.context = context

    def process_bind_param(self, value, dialect):
        return None if value is None else encrypt(value, self.context)

    def process_result_value(self, value, dialect):
        return None if value is None else decrypt(value, self.context)
