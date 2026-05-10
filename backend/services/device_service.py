import hashlib
import hmac
import secrets
import sqlite3
from http import HTTPStatus

from config import DEVICE_KEY
from services.errors import ApiError
from services.time_service import iso_now


def hash_device_key(device_key: str) -> str:
    return hashlib.sha256(device_key.encode()).hexdigest()


def create_device_key(db: sqlite3.Connection, box_id: str, device_key: str | None = None, label: str = "ESP32") -> str:
    raw_key = device_key or secrets.token_urlsafe(32)
    db.execute(
        """
        INSERT INTO device_keys (id, box_id, key_hash, label, created_at)
        VALUES (?, ?, ?, ?, ?)
        """,
        ("devkey-" + secrets.token_hex(8), box_id, hash_device_key(raw_key), label, iso_now()),
    )
    return raw_key


def ensure_demo_device_key(db: sqlite3.Connection, box_id: str) -> None:
    existing = db.execute(
        "SELECT 1 FROM device_keys WHERE box_id = ? AND revoked_at IS NULL LIMIT 1",
        (box_id,),
    ).fetchone()
    if existing is None:
        create_device_key(db, box_id, DEVICE_KEY, "Demo ESP32")


def require_valid_device_key(db: sqlite3.Connection, box_id: str, device_key: str) -> None:
    if not device_key:
        raise ApiError(HTTPStatus.UNAUTHORIZED, "Invalid device key.")

    candidates = db.execute(
        """
        SELECT key_hash FROM device_keys
        WHERE box_id = ? AND revoked_at IS NULL
        """,
        (box_id,),
    ).fetchall()
    presented = hash_device_key(device_key)
    if not any(hmac.compare_digest(row["key_hash"], presented) for row in candidates):
        raise ApiError(HTTPStatus.UNAUTHORIZED, "Invalid device key.")
