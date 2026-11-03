"""Database tables. All access goes through the SQLAlchemy ORM, which sends
values as bound parameters - user input is never concatenated into SQL."""
from __future__ import annotations

import enum
import uuid
from datetime import date, datetime, timezone

from sqlalchemy import (
    Boolean,
    Column,
    Date,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    Table,
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

    # Two-factor authentication (TOTP). Secret is encrypted at rest.
    mfa_secret: Mapped[str | None] = mapped_column(EncryptedText, nullable=True)
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
    mfa_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    last_seen_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    ip: Mapped[str] = mapped_column(String(64), default="")
    user_agent: Mapped[str] = mapped_column(String(300), default="")
    revoked: Mapped[bool] = mapped_column(Boolean, default=False)

    user: Mapped[User] = relationship()


class OneTimeCode(Base):
    """Emailed 6-digit codes for password reset / password change.
    Stored hashed, expire quickly, single use, limited attempts."""

    __tablename__ = "one_time_codes"
    id: Mapped[str] = mapped_column(String(32), primary_key=True, default=new_id)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    purpose: Mapped[str] = mapped_column(String(32))  # password_reset | password_change
    code_hash: Mapped[str] = mapped_column(String(64))
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    attempts: Mapped[int] = mapped_column(Integer, default=0)
    used: Mapped[bool] = mapped_column(Boolean, default=False)
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


student_specialists = Table(
    "student_specialists",
    Base.metadata,
    Column("student_id", ForeignKey("students.id", ondelete="CASCADE"), primary_key=True),
    Column("user_id", ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
)


class Student(Base):
    __tablename__ = "students"
    id: Mapped[str] = mapped_column(String(32), primary_key=True, default=new_id)
    institution_id: Mapped[str] = mapped_column(ForeignKey("institutions.id"), index=True)
    full_name: Mapped[str] = mapped_column(String(120))
    birth_date: Mapped[date] = mapped_column(Date)
    grade: Mapped[str] = mapped_column(String(20), default="")
    diagnosis: Mapped[str | None] = mapped_column(EncryptedText, nullable=True)
    guardian_name: Mapped[str] = mapped_column(String(120), default="")
    guardian_phone: Mapped[str | None] = mapped_column(EncryptedText, nullable=True)
    coordinator_id: Mapped[str | None] = mapped_column(ForeignKey("users.id"), nullable=True)
    archived: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

    specialists: Mapped[list[User]] = relationship(secondary=student_specialists)


class Assessment(Base):
    __tablename__ = "assessments"
    id: Mapped[str] = mapped_column(String(32), primary_key=True, default=new_id)
    student_id: Mapped[str] = mapped_column(ForeignKey("students.id", ondelete="CASCADE"), index=True)
    specialist_id: Mapped[str] = mapped_column(ForeignKey("users.id"))
    title: Mapped[str] = mapped_column(String(200))
    category: Mapped[str] = mapped_column(String(120), default="")
    assessment_date: Mapped[date] = mapped_column(Date)
    total_score: Mapped[float] = mapped_column(Float)
    max_score: Mapped[float] = mapped_column(Float)
    status: Mapped[str] = mapped_column(String(16), default="completed")
    notes: Mapped[str | None] = mapped_column(EncryptedText, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class Observation(Base):
    __tablename__ = "observations"
    id: Mapped[str] = mapped_column(String(32), primary_key=True, default=new_id)
    student_id: Mapped[str] = mapped_column(ForeignKey("students.id", ondelete="CASCADE"), index=True)
    psychologist_id: Mapped[str] = mapped_column(ForeignKey("users.id"))
    confidential: Mapped[bool] = mapped_column(Boolean, default=True)
    text: Mapped[str] = mapped_column(EncryptedText)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class RateCounter(Base):
    """Fixed-window counters shared by all workers (login and API limits)."""

    __tablename__ = "rate_counters"
    __table_args__ = (UniqueConstraint("key", "window"),)
    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    key: Mapped[str] = mapped_column(String(160), index=True)
    window: Mapped[int] = mapped_column(Integer)
    count: Mapped[int] = mapped_column(Integer, default=0)


__all__ = [
    "Assessment", "AuditEvent", "AuthSession", "Institution", "Observation",
    "OneTimeCode", "RateCounter", "Role", "Student", "User", "utcnow", "_tz",
]
