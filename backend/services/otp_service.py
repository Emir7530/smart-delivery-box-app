import secrets
import sqlite3
from datetime import datetime, timedelta
from typing import Any

from config import OTP_TTL_SECONDS
from services.time_service import iso_now, utc_now
from services.validators import require_fields


def otp_code() -> str:
    raw = f"{secrets.randbelow(1_000_000):06d}"
    return f"{raw[:3]} {raw[3:]}"


def current_otp(db: sqlite3.Connection, box_id: str) -> dict[str, Any]:
    row = db.execute(
        """
        SELECT * FROM otps
        WHERE box_id = ? AND used_at IS NULL
        ORDER BY created_at DESC
        LIMIT 1
        """,
        (box_id,),
    ).fetchone()
    if row is None:
        return create_otp(db, box_id)

    expires_at = datetime.fromisoformat(row["expires_at"].replace("Z", "+00:00"))
    if expires_at <= utc_now():
        return create_otp(db, box_id)

    remaining = max(0, int((expires_at - utc_now()).total_seconds()))
    return {
        "id": row["id"],
        "code": row["code"],
        "expiresAt": row["expires_at"],
        "expiresInSeconds": remaining,
        "expiresInLabel": f"{remaining // 60:02d}:{remaining % 60:02d}",
    }


def create_otp(db: sqlite3.Connection, box_id: str) -> dict[str, Any]:
    now = iso_now()
    expires = (utc_now() + timedelta(seconds=OTP_TTL_SECONDS)).replace(microsecond=0)
    row_id = "otp-" + secrets.token_hex(8)
    db.execute(
        """
        INSERT INTO otps (id, box_id, code, expires_at, created_at)
        VALUES (?, ?, ?, ?, ?)
        """,
        (row_id, box_id, otp_code(), expires.isoformat().replace("+00:00", "Z"), now),
    )
    return current_otp(db, box_id)


def verify_otp(db: sqlite3.Connection, box_id: str, data: dict[str, Any]) -> dict[str, Any]:
    from services.alert_service import create_alert

    require_fields(data, ["code"])
    code = str(data["code"]).strip()
    current = current_otp(db, box_id)
    if current["code"] != code:
        create_alert(
            db,
            box_id,
            {
                "title": "Wrong OTP entered",
                "message": "Invalid delivery code attempt",
                "severity": "warning",
                "attemptTimes": [datetime.now().strftime("%I:%M %p")],
            },
        )
        return {"valid": False, "message": "OTP code is invalid."}

    db.execute("UPDATE otps SET used_at = ? WHERE id = ?", (iso_now(), current["id"]))
    return {"valid": True, "message": "OTP verified successfully.", "otp": current}
