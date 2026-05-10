import base64
import hashlib
import hmac
import json
import time
from http import HTTPStatus
from typing import Any

from config import JWT_SECRET
from services.errors import ApiError


def json_dumps(value: Any) -> bytes:
    return json.dumps(value, ensure_ascii=False, separators=(",", ":")).encode()


def b64url_encode(raw: bytes) -> str:
    return base64.urlsafe_b64encode(raw).rstrip(b"=").decode()


def b64url_decode(value: str) -> bytes:
    padding = "=" * (-len(value) % 4)
    return base64.urlsafe_b64decode(value + padding)


def sign_token(payload: dict[str, Any]) -> str:
    raw_payload = json_dumps(payload)
    body = b64url_encode(raw_payload)
    signature = hmac.new(JWT_SECRET.encode(), body.encode(), hashlib.sha256).digest()
    return f"{body}.{b64url_encode(signature)}"


def verify_token(token: str) -> dict[str, Any]:
    try:
        body, signature = token.split(".", 1)
    except ValueError as exc:
        raise ApiError(HTTPStatus.UNAUTHORIZED, "Invalid auth token.") from exc

    expected = hmac.new(JWT_SECRET.encode(), body.encode(), hashlib.sha256).digest()
    if not hmac.compare_digest(b64url_encode(expected), signature):
        raise ApiError(HTTPStatus.UNAUTHORIZED, "Invalid auth token.")

    payload = json.loads(b64url_decode(body))
    if int(payload.get("exp", 0)) < int(time.time()):
        raise ApiError(HTTPStatus.UNAUTHORIZED, "Auth token expired.")
    return payload
