"""Server-side validation of every request body. Unknown fields are refused,
lengths are bounded, and markup/control characters are rejected in names."""
from __future__ import annotations

import re
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


_UZ_LOCAL = re.compile(r"^[2-9][0-9]{8}$")


def _uz_phone(value: str) -> str:
    """Uzbek numbers only: +998 and 9 digits. Stored one way, "+998 90 123 45 67",
    however it was typed (spaces, dashes, brackets, with or without 998)."""
    digits = re.sub(r"[ ()+-]", "", value or "")
    if not digits.isdigit():
        raise ValueError("telefon raqamida faqat raqamlar bo‘lsin")
    if len(digits) == 12 and digits.startswith("998"):
        digits = digits[3:]
    if not _UZ_LOCAL.match(digits):
        raise ValueError("faqat O‘zbekiston raqami: +998 XX XXX XX XX")
    return f"+998 {digits[:2]} {digits[2:5]} {digits[5:7]} {digits[7:]}"


UzPhone = Annotated[str, AfterValidator(_uz_phone)]


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
    remember: bool = False  # "Eslab qolish" (ignored for admin roles)


class CodeIn(Strict):
    code: str = Field(pattern=r"^\d{6}$")


class PasswordConfirmIn(Strict):
    password: str = Field(min_length=1, max_length=128)


class EmailCodeIn(Strict):
    code: str = Field(pattern=r"^\d{6}$")


class RecoveryCodeIn(Strict):
    # XXXX-XXXX from the list shown when 2FA was enabled; case and dash optional.
    code: str = Field(pattern=r"^[A-Za-z0-9]{4}-?[A-Za-z0-9]{4}$")


class PasswordChangeIn(Strict):
    current_password: str = Field(min_length=1, max_length=128)
    # Not needed for the forced first change of a temporary password: that
    # session has already passed the emailed login code.
    code: str | None = Field(default=None, pattern=r"^\d{6}$")
    new_password: str = Field(min_length=1, max_length=128)


# Roles a person may pick when signing up; everything else is created by an admin.
SELF_REGISTRATION_ROLES = {
    Role.PSYCHOLOGIST, Role.SPEECH_THERAPIST, Role.SPECIAL_EDUCATION,
    Role.SPECIAL_ED_TEACHER, Role.TEACHER,
}


class RegisterIn(Strict):
    first_name: PlainStr = Field(min_length=2, max_length=60)
    last_name: PlainStr = Field(min_length=2, max_length=60)
    email: EmailStr = Field(max_length=254)
    phone: UzPhone = Field(max_length=30)
    role: Role
    specialization: PlainStr = Field(default="", max_length=120)
    qualification_category: PlainStr = Field(default="", max_length=60)
    experience_years: int = Field(default=0, ge=0, le=60)
    region: PlainStr = Field(default="", max_length=100)
    district: PlainStr = Field(default="", max_length=100)
    institution_name: PlainStr = Field(min_length=2, max_length=200)
    password: str = Field(min_length=1, max_length=128)

    @field_validator("role")
    @classmethod
    def _self_service_role(cls, v: Role) -> Role:
        if v not in SELF_REGISTRATION_ROLES:
            raise ValueError("bu rol bilan o‘zingiz ro‘yxatdan o‘ta olmaysiz")
        return v


class RegistrationIdIn(Strict):
    registration_id: str = Field(pattern=r"^[a-f0-9]{32}$")


class RegistrationVerifyIn(RegistrationIdIn):
    code: str = Field(pattern=r"^\d{6}$")


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
    phone: UzPhone | None = Field(default=None, max_length=30)


class UserUpdateIn(Strict):
    full_name: PlainStr | None = Field(default=None, min_length=3, max_length=120)
    role: Role | None = None
    is_active: bool | None = None
    institution_id: str | None = Field(default=None, pattern=r"^[a-f0-9]{32}$")


class ProfileUpdateIn(Strict):
    """What a person may change about themselves. Email (the login), role and
    school are not here: those go through an administrator."""
    first_name: PlainStr | None = Field(default=None, min_length=2, max_length=60)
    last_name: PlainStr | None = Field(default=None, min_length=2, max_length=60)
    middle_name: PlainStr | None = Field(default=None, max_length=60)
    phone: UzPhone | None = Field(default=None, max_length=30)
    specialization: PlainStr | None = Field(default=None, max_length=120)
    qualification_category: PlainStr | None = Field(default=None, max_length=60)
    experience_years: int | None = Field(default=None, ge=0, le=60)
    region: PlainStr | None = Field(default=None, max_length=100)
    district: PlainStr | None = Field(default=None, max_length=100)


class ApproveIn(Strict):
    institution_id: str = Field(pattern=r"^[a-f0-9]{32}$")


class InstitutionIn(Strict):
    name: PlainStr = Field(min_length=3, max_length=200)
    region: PlainStr = Field(default="", max_length=100)


RECORD_KINDS = (
    "student|assessment|session|iep|referral|observation|assessment_plan|subject_level|"
    "measurement|subject_task|achievement|conference|sound_entry|notification|question|"
    "curriculum|custom_metric"
)


class RecordOp(BaseModel):
    # `data` is the app's own JSON for the item; it is stored encrypted and
    # only ever returned as JSON, so its text is never interpreted as markup.
    model_config = ConfigDict(extra="forbid")
    op: str = Field(pattern=r"^(put|delete)$")
    kind: str = Field(pattern=rf"^({RECORD_KINDS})$")
    id: str = Field(min_length=1, max_length=64, pattern=r"^[A-Za-z0-9_.:-]+$")
    data: dict | None = None
    # Offline edits: the version the device last saw. If the record has changed
    # since, the batch is refused with 409 instead of overwriting someone's work.
    base_version: int | None = Field(default=None, ge=1)


class BatchIn(BaseModel):
    model_config = ConfigDict(extra="forbid")
    ops: list[RecordOp] = Field(min_length=1, max_length=500)
