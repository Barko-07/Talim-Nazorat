"""Server configuration, read only from environment variables.

Secrets never live in code or git. In production the app refuses to start
when a secret is missing, weak or an unsafe option is enabled.
"""
from __future__ import annotations

import base64
import os
from dataclasses import dataclass, field


class ConfigError(RuntimeError):
    pass


def _bool(name: str, default: bool) -> bool:
    raw = os.environ.get(name)
    if raw is None:
        return default
    return raw.strip().lower() in {"1", "true", "yes", "on"}


def _int(name: str, default: int) -> int:
    raw = os.environ.get(name)
    return default if raw is None or raw.strip() == "" else int(raw)


def _list(name: str) -> list[str]:
    raw = os.environ.get(name, "")
    return [x.strip() for x in raw.split(",") if x.strip()]


@dataclass(frozen=True)
class Settings:
    environment: str  # "production" | "development" | "test"
    database_url: str
    secret_key: str  # HMAC key for CSRF tokens and code hashing
    data_encryption_key: bytes  # 32-byte AES-256-GCM key for sensitive columns
    allowed_origins: list[str]
    public_base_url: str

    # Sessions
    session_idle_minutes: int = 30
    session_absolute_hours: int = 8
    cookie_secure: bool = True

    # Login protection
    login_max_failures: int = 5
    login_lock_minutes: int = 15
    login_ip_per_minute: int = 10
    api_per_minute: int = 120

    # Password / reset codes
    code_ttl_minutes: int = 10
    code_max_attempts: int = 5
    code_resend_seconds: int = 60  # minimum gap between two emailed codes

    # "Eslab qolish" on the login page keeps a non-admin signed in this long
    remember_me_days: int = 30

    # Roles that must also set up an authenticator app. Empty by default: every
    # login (admins included) is confirmed with a code emailed to the account.
    mfa_required_roles: list[str] = field(default_factory=list)

    # Admin
    admin_ip_allowlist: list[str] = field(default_factory=list)
    trusted_proxies: list[str] = field(default_factory=lambda: ["127.0.0.1", "::1"])

    # Outbound mail for one-time codes
    smtp_host: str = ""
    smtp_port: int = 587
    smtp_user: str = ""
    smtp_password: str = ""
    smtp_from: str = ""

    # Optional alert webhook for suspicious activity (e.g. a Telegram bot relay)
    alert_webhook_url: str = ""

    max_body_bytes: int = 256 * 1024

    @property
    def is_production(self) -> bool:
        return self.environment == "production"


def _decode_key(raw: str) -> bytes:
    try:
        key = base64.urlsafe_b64decode(raw + "=" * (-len(raw) % 4))
    except Exception as exc:  # noqa: BLE001
        raise ConfigError("DATA_ENCRYPTION_KEY must be base64") from exc
    if len(key) != 32:
        raise ConfigError("DATA_ENCRYPTION_KEY must decode to exactly 32 bytes")
    return key


def load_settings() -> Settings:
    env = os.environ.get("INDIVID_ENV", "development").strip().lower()
    if env not in {"production", "development", "test"}:
        raise ConfigError("INDIVID_ENV must be production, development or test")

    secret = os.environ.get("SECRET_KEY", "")
    enc = os.environ.get("DATA_ENCRYPTION_KEY", "")
    db_url = os.environ.get("DATABASE_URL", "")

    if env != "production":
        # Throwaway values so local development and tests work without setup.
        secret = secret or "dev-only-secret-key-not-for-production-use-0000"
        enc = enc or base64.urlsafe_b64encode(b"\x00" * 32).decode()
        db_url = db_url or "sqlite:///./individ-dev.db"

    settings = Settings(
        environment=env,
        database_url=db_url,
        secret_key=secret,
        data_encryption_key=_decode_key(enc) if enc else b"",
        allowed_origins=_list("ALLOWED_ORIGINS"),
        public_base_url=os.environ.get("PUBLIC_BASE_URL", "").rstrip("/"),
        session_idle_minutes=_int("SESSION_IDLE_MINUTES", 30),
        session_absolute_hours=_int("SESSION_ABSOLUTE_HOURS", 8),
        cookie_secure=_bool("COOKIE_SECURE", env == "production"),
        login_max_failures=_int("LOGIN_MAX_FAILURES", 5),
        login_lock_minutes=_int("LOGIN_LOCK_MINUTES", 15),
        login_ip_per_minute=_int("LOGIN_IP_PER_MINUTE", 10),
        api_per_minute=_int("API_PER_MINUTE", 120),
        code_ttl_minutes=_int("CODE_TTL_MINUTES", 10),
        code_max_attempts=_int("CODE_MAX_ATTEMPTS", 5),
        code_resend_seconds=_int("CODE_RESEND_SECONDS", 60),
        remember_me_days=_int("REMEMBER_ME_DAYS", 30),
        mfa_required_roles=_list("MFA_REQUIRED_ROLES"),
        admin_ip_allowlist=_list("ADMIN_IP_ALLOWLIST"),
        trusted_proxies=_list("TRUSTED_PROXIES") or ["127.0.0.1", "::1"],
        smtp_host=os.environ.get("SMTP_HOST", ""),
        smtp_port=_int("SMTP_PORT", 587),
        smtp_user=os.environ.get("SMTP_USER", ""),
        smtp_password=os.environ.get("SMTP_PASSWORD", ""),
        smtp_from=os.environ.get("SMTP_FROM", ""),
        alert_webhook_url=os.environ.get("ALERT_WEBHOOK_URL", ""),
    )
    if settings.is_production:
        problems = production_problems(settings)
        if problems:
            raise ConfigError("Unsafe production configuration:\n- " + "\n- ".join(problems))
    return settings


def production_problems(s: Settings) -> list[str]:
    p: list[str] = []
    if len(s.secret_key) < 48 or "dev-only" in s.secret_key:
        p.append("SECRET_KEY must be a random value of at least 48 characters")
    if not s.data_encryption_key or s.data_encryption_key == b"\x00" * 32:
        p.append("DATA_ENCRYPTION_KEY must be a random 32-byte key")
    if not s.database_url.startswith("postgresql"):
        p.append("DATABASE_URL must point to PostgreSQL in production")
    if not s.cookie_secure:
        p.append("COOKIE_SECURE must stay enabled in production")
    if not s.public_base_url.startswith("https://"):
        p.append("PUBLIC_BASE_URL must start with https://")
    if any(o == "*" or not o.startswith("https://") for o in s.allowed_origins):
        p.append("ALLOWED_ORIGINS may only list https:// origins (never *)")
    if not (s.smtp_host and s.smtp_from):
        p.append("SMTP_HOST and SMTP_FROM are required to deliver one-time codes")
    return p
