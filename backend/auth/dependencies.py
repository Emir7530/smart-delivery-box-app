from http import HTTPStatus

from fastapi import Header

from auth.token import verify_token
from db import session
from services.errors import ApiError
from services.device_service import require_valid_device_key


def require_user_id(authorization: str = Header(default="")) -> str:
    if not authorization.startswith("Bearer "):
        raise ApiError(HTTPStatus.UNAUTHORIZED, "Missing bearer token.")
    payload = verify_token(authorization.removeprefix("Bearer ").strip())
    return str(payload["sub"])


def require_device_key(box_id: str, x_device_key: str = Header(default="")) -> None:
    with session() as db:
        require_valid_device_key(db, box_id, x_device_key)
