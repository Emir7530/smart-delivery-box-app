import sqlite3
from http import HTTPStatus
from typing import Any

from config import DEFAULT_BOX_ID
from services.errors import ApiError
from services.serializers import alert_payload, box_payload, command_payload, delivery_payload


def get_user(db: sqlite3.Connection, user_id: str) -> sqlite3.Row:
    user = db.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
    if user is None:
        raise ApiError(HTTPStatus.UNAUTHORIZED, "User not found.")
    return user


def get_box(db: sqlite3.Connection, box_id: str) -> sqlite3.Row:
    box = db.execute("SELECT * FROM boxes WHERE id = ?", (box_id,)).fetchone()
    if box is None:
        raise ApiError(HTTPStatus.NOT_FOUND, "Box not found.")
    return box


def require_box_access(db: sqlite3.Connection, box_id: str, user_id: str) -> None:
    box = db.execute(
        "SELECT 1 FROM boxes WHERE id = ? AND owner_user_id = ?",
        (box_id, user_id),
    ).fetchone()
    if box is None:
        raise ApiError(HTTPStatus.NOT_FOUND, "Box not found for this user.")


def api_index() -> dict[str, Any]:
    return {
        "service": "Smart Drop-Off Box Backend",
        "version": "1.0",
        "demoAccount": {"email": "emir@example.com", "password": "123456"},
        "demoBoxId": DEFAULT_BOX_ID,
        "endpoints": [
            "POST /api/auth/register",
            "POST /api/auth/login",
            "GET /api/boxes/{boxId}/snapshot",
            "GET /api/boxes/{boxId}/state",
            "POST /api/boxes/{boxId}/commands",
            "GET /api/boxes/{boxId}/otp",
            "POST /api/boxes/{boxId}/otp/regenerate",
            "GET /api/boxes/{boxId}/deliveries",
            "GET /api/boxes/{boxId}/alerts",
            "GET /api/boxes/{boxId}/embedded/commands",
            "POST /api/boxes/{boxId}/embedded/telemetry",
            "POST /api/boxes/{boxId}/embedded/delivery",
            "POST /api/boxes/{boxId}/embedded/alerts",
            "POST /api/boxes/{boxId}/embedded/otp/verify",
        ],
    }


def get_box_state(db: sqlite3.Connection, box_id: str) -> dict[str, Any]:
    return {"box": box_payload(get_box(db, box_id))}


def box_snapshot(db: sqlite3.Connection, box_id: str) -> dict[str, Any]:
    from services.otp_service import current_otp

    return {
        "box": box_payload(get_box(db, box_id)),
        "otp": current_otp(db, box_id),
        "deliveries": [
            delivery_payload(row)
            for row in db.execute(
                "SELECT * FROM deliveries WHERE box_id = ? ORDER BY delivered_at DESC",
                (box_id,),
            ).fetchall()
        ],
        "alerts": [
            alert_payload(row)
            for row in db.execute(
                "SELECT * FROM alerts WHERE box_id = ? ORDER BY created_at DESC",
                (box_id,),
            ).fetchall()
        ],
    }


def list_deliveries(db: sqlite3.Connection, box_id: str) -> dict[str, Any]:
    rows = db.execute(
        "SELECT * FROM deliveries WHERE box_id = ? ORDER BY delivered_at DESC",
        (box_id,),
    ).fetchall()
    return {"deliveries": [delivery_payload(row) for row in rows]}


def list_alerts(db: sqlite3.Connection, box_id: str) -> dict[str, Any]:
    rows = db.execute(
        "SELECT * FROM alerts WHERE box_id = ? ORDER BY created_at DESC",
        (box_id,),
    ).fetchall()
    return {"alerts": [alert_payload(row) for row in rows]}


def list_commands(db: sqlite3.Connection, box_id: str) -> dict[str, Any]:
    rows = db.execute(
        "SELECT * FROM commands WHERE box_id = ? ORDER BY requested_at DESC LIMIT 20",
        (box_id,),
    ).fetchall()
    return {"commands": [command_payload(row) for row in rows]}
