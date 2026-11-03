"""Server-side validation of every request body. Unknown fields are refused,
lengths are bounded, and markup/control characters are rejected in names."""
from __future__ import annotations

import re
from datetime import date
from typing import Annotated

from pydantic import AfterValidator, BaseModel, ConfigDict, EmailStr, Field, field_validator

from .models import Role

_CONTROL = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]")
_MARKUP = re.compile(r"[<>]|javascript:|data:text/html", re.IGNORECASE)


def _plain(value: str) -> str:
    value = value.strip()
    if _CONTROL.search(value):
        raise ValueError("boshqaruv belgilari ruxsat etilmaydi")
    if _MARKUP.search(value):
        raise ValueError("HTML yoki skript belgilariga ruxsat yo‘q")
    return value


def _text(value: str) -> str:
    # Free text (notes) may contain < and >; Flutter renders it as plain text
    # and the API only returns JSON, so it is never interpreted as HTML.
    value = value.strip()
    if _CONTROL.search(value):
        raise ValueError("boshqaruv belgilari ruxsat etilmaydi")
    return value


PlainStr = Annotated[str, AfterValidator(_plain)]
NoteStr = Annotated[str, AfterValidator(_text)]


class Strict(BaseModel):
    model_config = ConfigDict(extra="forbid", str_max_length=5000)


class LoginIn(Strict):
    email: EmailStr = Field(max_length=254)
    password: str = Field(min_length=1, max_length=128)


class CodeIn(Strict):
    code: str = Field(pattern=r"^\d{6}$")


class PasswordConfirmIn(Strict):
    password: str = Field(min_length=1, max_length=128)


class PasswordChangeIn(Strict):
    current_password: str = Field(min_length=1, max_length=128)
    code: str = Field(pattern=r"^\d{6}$")
    new_password: str = Field(min_length=1, max_length=128)


class ResetRequestIn(Strict):
    email: EmailStr = Field(max_length=254)


class ResetConfirmIn(Strict):
    email: EmailStr = Field(max_length=254)
    code: str = Field(pattern=r"^\d{6}$")
    new_password: str = Field(min_length=1, max_length=128)


class UserCreateIn(Strict):
    email: EmailStr = Field(max_length=254)
    full_name: PlainStr = Field(min_length=3, max_length=120)
    role: Role
    institution_id: str | None = Field(default=None, pattern=r"^[a-f0-9]{32}$")
    phone: str | None = Field(default=None, pattern=r"^\+?[0-9 ()-]{7,20}$")


class UserUpdateIn(Strict):
    full_name: PlainStr | None = Field(default=None, min_length=3, max_length=120)
    role: Role | None = None
    is_active: bool | None = None


class InstitutionIn(Strict):
    name: PlainStr = Field(min_length=3, max_length=200)
    region: PlainStr = Field(default="", max_length=100)


class StudentIn(Strict):
    full_name: PlainStr = Field(min_length=3, max_length=120)
    birth_date: date
    grade: PlainStr = Field(default="", max_length=20)
    diagnosis: NoteStr | None = Field(default=None, max_length=2000)
    guardian_name: PlainStr = Field(default="", max_length=120)
    guardian_phone: str | None = Field(default=None, pattern=r"^\+?[0-9 ()-]{7,20}$")
    institution_id: str | None = Field(default=None, pattern=r"^[a-f0-9]{32}$")

    @field_validator("birth_date")
    @classmethod
    def _sane_birth_date(cls, v: date) -> date:
        if not date(1990, 1, 1) <= v <= date.today():
            raise ValueError("tug‘ilgan sana noto‘g‘ri")
        return v


class AssignIn(Strict):
    user_id: str = Field(pattern=r"^[a-f0-9]{32}$")


class AssessmentIn(Strict):
    title: PlainStr = Field(min_length=2, max_length=200)
    category: PlainStr = Field(default="", max_length=120)
    assessment_date: date
    total_score: float = Field(ge=0, le=10_000)
    max_score: float = Field(gt=0, le=10_000)
    status: str = Field(default="completed", pattern=r"^(completed|draft)$")
    notes: NoteStr | None = Field(default=None, max_length=5000)

    @field_validator("total_score")
    @classmethod
    def _finite(cls, v: float) -> float:
        if v != v or v in (float("inf"), float("-inf")):
            raise ValueError("son noto‘g‘ri")
        return v


class ObservationIn(Strict):
    text: NoteStr = Field(min_length=1, max_length=5000)
    confidential: bool = True
