import json
import sqlite3
import secrets
from http import HTTPStatus
from typing import Any

from services.errors import ApiError
from services.serializers import alert_payload
from services.time_service import iso_now
from services.validators import require_fields


def create_alert(db: sqlite3.Connection, box_id: str, data: dict[str, Any]) -> dict[str, Any]:
    require_fields(data, ["title", "message", "severity"])
    severity = str(data["severity"]).strip()
    if severity not in {"critical", "warning", "success", "battery"}:
        raise ApiError(HTTPStatus.BAD_REQUEST, "Invalid alert severity.")

    alert_id = "alert-" + secrets.token_hex(8)
    db.execute(
        """
        INSERT INTO alerts (id, box_id, title, message, severity, attempt_times, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        """,
        (
            alert_id,
            box_id,
            str(data["title"]).strip(),
            str(data["message"]).strip(),
            severity,
            json.dumps(data.get("attemptTimes", [])),
            str(data.get("createdAt", iso_now())),
        ),
    )
    return alert_payload(db.execute("SELECT * FROM alerts WHERE id = ?", (alert_id,)).fetchone())
