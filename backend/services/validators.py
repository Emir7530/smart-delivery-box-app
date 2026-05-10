from http import HTTPStatus
from typing import Any

from services.errors import ApiError


def require_fields(data: dict[str, Any], fields: list[str]) -> None:
    missing = [field for field in fields if not str(data.get(field, "")).strip()]
    if missing:
        raise ApiError(HTTPStatus.BAD_REQUEST, f"Missing required field(s): {', '.join(missing)}.")


def normalize_email(email: str) -> str:
    return email.strip().lower()


def validate_phone(phone: str) -> None:
    if len(phone) != 11 or not phone.startswith("0") or not phone.isdigit():
        raise ApiError(HTTPStatus.BAD_REQUEST, "Phone number must start with 0 and be 11 digits.")
