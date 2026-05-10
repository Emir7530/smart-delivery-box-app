import secrets
import sqlite3
import time
from http import HTTPStatus
from typing import Any

from auth.security import check_password, hash_password
from auth.token import sign_token
from config import DEVICE_KEY, TOKEN_TTL_SECONDS
from services.box_service import get_user
from services.device_service import create_device_key
from services.errors import ApiError
from services.otp_service import create_otp
from services.serializers import box_payload, public_user
from services.time_service import iso_now
from services.validators import normalize_email, require_fields, validate_phone


def auth_response(user: sqlite3.Row, db: sqlite3.Connection) -> dict[str, Any]:
    token = sign_token(
        {
            "sub": user["id"],
            "email": user["email"],
            "exp": int(time.time()) + TOKEN_TTL_SECONDS,
        }
    )
    boxes = db.execute("SELECT * FROM boxes WHERE owner_user_id = ?", (user["id"],)).fetchall()
    return {
        "token": token,
        "user": public_user(user),
        "boxes": [box_payload(box) for box in boxes],
    }


def register(db: sqlite3.Connection, data: dict[str, Any]) -> dict[str, Any]:
    require_fields(data, ["fullName", "email", "phone", "password", "confirmPassword"])

    full_name = str(data["fullName"]).strip()
    email = normalize_email(str(data["email"]))
    phone = str(data["phone"]).strip()
    password = str(data["password"]).strip()
    confirm_password = str(data["confirmPassword"]).strip()

    if "@" not in email or "." not in email:
        raise ApiError(HTTPStatus.BAD_REQUEST, "Enter a valid email address.")
    validate_phone(phone)
    if len(password) < 6:
        raise ApiError(HTTPStatus.BAD_REQUEST, "Password must be at least 6 characters.")
    if password != confirm_password:
        raise ApiError(HTTPStatus.BAD_REQUEST, "Passwords do not match.")

    existing = db.execute("SELECT 1 FROM users WHERE email = ?", (email,)).fetchone()
    if existing:
        raise ApiError(HTTPStatus.CONFLICT, "An account with this email already exists.")

    user_id = "user-" + secrets.token_hex(8)
    salt, password_hash = hash_password(password)
    now = iso_now()
    db.execute(
        """
        INSERT INTO users
        (id, full_name, email, phone, password_salt, password_hash, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        """,
        (user_id, full_name, email, phone, salt, password_hash, now),
    )
    box_id = "box-" + secrets.token_hex(6)
    db.execute(
        """
        INSERT INTO boxes
        (id, owner_user_id, label, is_locked, has_package, is_online, battery_percent,
         firmware_version, last_seen_at, updated_at)
        VALUES (?, ?, ?, 1, 0, 1, 100, 'esp32-unpaired', ?, ?)
        """,
        (box_id, user_id, "Smart Drop-Off Box", now, now),
    )
    create_otp(db, box_id)
    create_device_key(db, box_id, DEVICE_KEY)
    db.commit()

    return auth_response(get_user(db, user_id), db)


def login(db: sqlite3.Connection, data: dict[str, Any]) -> dict[str, Any]:
    require_fields(data, ["email", "password"])
    email = normalize_email(str(data["email"]))
    password = str(data["password"]).strip()

    user = db.execute("SELECT * FROM users WHERE email = ?", (email,)).fetchone()
    if user is None or not check_password(password, user["password_salt"], user["password_hash"]):
        raise ApiError(HTTPStatus.UNAUTHORIZED, "No account matches those credentials.")
    return auth_response(user, db)
