"""Database tables. All access goes through the SQLAlchemy ORM, which sends
values as bound parameters - user input is never concatenated into SQL."""
from __future__ import annotations

import enum
import uuid
from datetime import datetime, timezone

from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
    ForeignKey,
    Integer,
    String,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .crypto import EncryptedText
from .db import Base


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


def new_id() -> str:
    return uuid.uuid4().hex


class Role(str, enum.Enum):
    """Same codes as UserRole.code in the Flutter app."""

    SUPER_ADMIN = "SUPER_ADMIN"
    INSTITUTION_ADMIN = "INSTITUTION_ADMIN"
    COORDINATOR = "COORDINATOR"
    PSYCHOLOGIST = "PSYCHOLOGIST"
    SPEECH_THERAPIST = "SPEECH_THERAPIST"
    SPECIAL_EDUCATION = "SPECIAL_EDUCATION"
    SPECIAL_ED_TEACHER = "SPECIAL_ED_TEACHER"
    TEACHER = "TEACHER"
    REVIEWER = "REVIEWER"
    PARENT = "PARENT"


def _tz(dt: datetime | None) -> datetime | None:
    """SQLite drops tzinfo; treat stored values as UTC."""
    if dt is None or dt.tzinfo is not None:
        return dt
    return dt.replace(tzinfo=timezone.utc)


class Institution(Base):
    __tablename__ = "institutions"
    id: Mapped[str] = mapped_column(String(32), primary_key=True, default=new_id)
    name: Mapped[str] = mapped_column(String(200))
    region: Mapped[str] = mapped_column(String(100), default="")


class User(Base):
    __tablename__ = "users"
    id: Mapped[str] = mapped_column(String(32), primary_key=True, default=new_id)
    email: Mapped[str] = mapped_column(String(254), unique=True, index=True)
    full_name: Mapped[str] = mapped_column(String(120))
    role: Mapped[str] = mapped_column(String(32))
    institution_id: Mapped[str | None] = mapped_column(
        ForeignKey("institutions.id"), nullable=True
    )
    phone: Mapped[str | None] = mapped_column(String(32), nullable=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    must_change_password: Mapped[bool] = mapped_column(Boolean, default=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    # Self-registered accounts wait here until an administrator approves them.
    pending_approval: Mapped[bool] = mapped_column(Boolean, default=False)
    # Profile details from the app (region, district, school name, specialization,
    # qualification, experience) as encrypted JSON.
    profile: Mapped[str | None] = mapped_column(EncryptedText("users.profile"), nullable=True)

    # Two-factor authentication (TOTP). Secret is encrypted at rest.
    mfa_secret: Mapped[str | None] = mapped_column(EncryptedText("users.mfa_secret"), nullable=True)
    mfa_enabled: Mapped[bool] = mapped_column(Boolean, default=False)
    mfa_last_step: Mapped[int] = mapped_column(Integer, default=0)  # replay guard

    failed_logins: Mapped[int] = mapped_column(Integer, default=0)
    locked_until: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    password_changed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

    def locked_now(self, now: datetime) -> bool:
        lu = _tz(self.locked_until)
        return lu is not None and lu > now


class AuthSession(Base):
    """Server-side session. The browser holds only a random token; the DB
    stores its HMAC, so a DB leak does not reveal usable session tokens."""

    __tablename__ = "auth_sessions"
    id: Mapped[str] = mapped_column(String(32), primary_key=True, default=new_id)
    token_hash: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    # Second factor done in this session (authenticator, recovery code, emailed
    # code or a remembered device); `factor` says which, for the audit trail.
    mfa_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    factor: Mapped[str] = mapped_column(String(16), default="")
    remember: Mapped[bool] = mapped_column(Boolean, default=False)  # "Eslab qolish"
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    last_seen_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    ip: Mapped[str] = mapped_column(String(64), default="")
    user_agent: Mapped[str] = mapped_column(String(300), default="")
    revoked: Mapped[bool] = mapped_column(Boolean, default=False)

    user: Mapped[User] = relationship()


class OneTimeCode(Base):
    """Emailed 6-digit codes for login, password reset and password change.
    Stored hashed, expire quickly, single use, limited attempts."""

    __tablename__ = "one_time_codes"
    id: Mapped[str] = mapped_column(String(32), primary_key=True, default=new_id)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    purpose: Mapped[str] = mapped_column(String(32))  # login | password_reset | password_change
    code_hash: Mapped[str] = mapped_column(String(64))
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    attempts: Mapped[int] = mapped_column(Integer, default=0)
    used: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class RecoveryCode(Base):
    """Single-use backup codes for when the authenticator phone is lost.
    Only HMACs are stored; the codes are shown once, when 2FA is enabled."""

    __tablename__ = "recovery_codes"
    id: Mapped[str] = mapped_column(String(32), primary_key=True, default=new_id)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    code_hash: Mapped[str] = mapped_column(String(64))
    used_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class PendingRegistration(Base):
    """A sign-up waiting for its emailed code. No account exists until the code
    is confirmed; the form (with the already-hashed password) is encrypted."""

    __tablename__ = "pending_registrations"
    id: Mapped[str] = mapped_column(String(32), primary_key=True, default=new_id)
    email: Mapped[str] = mapped_column(String(254), index=True)
    data: Mapped[str] = mapped_column(EncryptedText("pending_registrations.data"))
    code_hash: Mapped[str] = mapped_column(String(64))
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    attempts: Mapped[int] = mapped_column(Integer, default=0)
    sends: Mapped[int] = mapped_column(Integer, default=1)
    last_sent_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class AuditEvent(Base):
    """Append-only. In PostgreSQL the app role gets INSERT/SELECT only
    (deploy/postgres/setup.sql), so entries cannot be edited or deleted."""

    __tablename__ = "audit_events"
    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)
    action: Mapped[str] = mapped_column(String(64), index=True)
    severity: Mapped[str] = mapped_column(String(16), default="info")  # info|warning|alert
    user_id: Mapped[str | None] = mapped_column(String(32), nullable=True)
    subject: Mapped[str] = mapped_column(String(120), default="")  # masked login, entity id
    ip: Mapped[str] = mapped_column(String(64), default="")
    detail: Mapped[str] = mapped_column(String(500), default="")


class Record(Base):
    """Every piece of work data the app keeps - children, assessments, sessions,
    plans, notes, referrals and the rest - one row per item. The item itself is
    encrypted JSON (`data`); only what the server needs to decide who may see it
    is stored in the clear: the school, the child it belongs to, its author."""

    __tablename__ = "records"
    kind: Mapped[str] = mapped_column(String(32), primary_key=True)
    rid: Mapped[str] = mapped_column(String(64), primary_key=True)
    institution_id: Mapped[str | None] = mapped_column(ForeignKey("institutions.id"), nullable=True, index=True)
    student_id: Mapped[str | None] = mapped_column(String(64), nullable=True, index=True)
    owner_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    recipient_id: Mapped[str | None] = mapped_column(String(32), nullable=True, index=True)
    confidential: Mapped[bool] = mapped_column(Boolean, default=False)
    data: Mapped[str] = mapped_column(EncryptedText("records.data"))
    deleted: Mapped[bool] = mapped_column(Boolean, default=False)
    version: Mapped[int] = mapped_column(Integer, default=1)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_by: Mapped[str | None] = mapped_column(String(32), nullable=True)


class StudentAccess(Base):
    """Who works with a child. Apart from administrators, only these people
    can see the child and anything recorded about them."""

    __tablename__ = "student_access"
    student_id: Mapped[str] = mapped_column(String(64), primary_key=True)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), primary_key=True, index=True)
    via: Mapped[str] = mapped_column(String(16), default="assigned")  # assigned | coordinator


class RecordChange(Base):
    """Append-only history of every add, edit and delete, for administrators.
    Field names are in the clear; old and new values are encrypted."""

    __tablename__ = "record_changes"
    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)
    user_id: Mapped[str] = mapped_column(String(32), index=True)
    kind: Mapped[str] = mapped_column(String(32))
    rid: Mapped[str] = mapped_column(String(64))
    student_id: Mapped[str | None] = mapped_column(String(64), nullable=True, index=True)
    institution_id: Mapped[str | None] = mapped_column(String(32), nullable=True, index=True)
    action: Mapped[str] = mapped_column(String(16))  # create | update | delete
    fields: Mapped[str] = mapped_column(String(1000), default="")
    before: Mapped[str | None] = mapped_column(EncryptedText("record_changes.before"), nullable=True)
    after: Mapped[str | None] = mapped_column(EncryptedText("record_changes.after"), nullable=True)


class RateCounter(Base):
    """Fixed-window counters shared by all workers (login and API limits)."""

    __tablename__ = "rate_counters"
    __table_args__ = (UniqueConstraint("key", "window"),)
    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    key: Mapped[str] = mapped_column(String(160), index=True)
    window: Mapped[int] = mapped_column(Integer)
    count: Mapped[int] = mapped_column(Integer, default=0)


__all__ = [
    "AuditEvent", "AuthSession", "Institution", "OneTimeCode", "RateCounter", "Record",
    "RecordChange", "Role", "StudentAccess", "User", "utcnow", "_tz",
]
