import secrets
import sqlite3
from http import HTTPStatus
from typing import Any

from services.errors import ApiError
from services.serializers import command_payload
from services.time_service import iso_now


def create_command(db: sqlite3.Connection, box_id: str, user_id: str, data: dict[str, Any]) -> dict[str, Any]:
    command = str(data.get("command", "")).strip().lower()
    if command not in {"lock", "unlock"}:
        raise ApiError(HTTPStatus.BAD_REQUEST, "Command must be 'lock' or 'unlock'.")

    now = iso_now()
    command_id = "cmd-" + secrets.token_hex(8)
    db.execute(
        """
        INSERT INTO commands (id, box_id, command, status, requested_by, requested_at)
        VALUES (?, ?, ?, 'pending', ?, ?)
        """,
        (command_id, box_id, command, user_id, now),
    )

    return command_payload(db.execute("SELECT * FROM commands WHERE id = ?", (command_id,)).fetchone())


def list_pending_commands(db: sqlite3.Connection, box_id: str) -> dict[str, Any]:
    rows = db.execute(
        """
        SELECT * FROM commands
        WHERE box_id = ? AND status = 'pending'
        ORDER BY requested_at ASC
        """,
        (box_id,),
    ).fetchall()
    return {"commands": [command_payload(row) for row in rows]}


def complete_command(db: sqlite3.Connection, box_id: str, command_id: str, data: dict[str, Any]) -> dict[str, Any]:
    row = db.execute(
        "SELECT * FROM commands WHERE id = ? AND box_id = ?",
        (command_id, box_id),
    ).fetchone()
    if row is None:
        raise ApiError(HTTPStatus.NOT_FOUND, "Command not found.")

    status = str(data.get("status", "completed")).strip().lower()
    if status not in {"completed", "failed"}:
        raise ApiError(HTTPStatus.BAD_REQUEST, "Status must be completed or failed.")

    now = iso_now()
    db.execute(
        "UPDATE commands SET status = ?, completed_at = ? WHERE id = ?",
        (status, now, command_id),
    )
    if status == "completed":
        db.execute(
            "UPDATE boxes SET is_locked = ?, is_online = 1, last_seen_at = ?, updated_at = ? WHERE id = ?",
            (1 if row["command"] == "lock" else 0, now, now, box_id),
        )

    return command_payload(db.execute("SELECT * FROM commands WHERE id = ?", (command_id,)).fetchone())
