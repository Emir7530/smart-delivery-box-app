import sqlite3
from typing import Any

from services.alert_service import create_alert
from services.serializers import box_payload
from services.time_service import iso_now


def update_telemetry(db: sqlite3.Connection, box_id: str, data: dict[str, Any]) -> dict[str, Any]:
    box = db.execute("SELECT * FROM boxes WHERE id = ?", (box_id,)).fetchone()
    now = iso_now()
    is_locked = int(bool(data.get("isLocked", bool(box["is_locked"]))))
    has_package = int(bool(data.get("hasPackage", bool(box["has_package"]))))
    is_online = int(bool(data.get("isOnline", True)))
    battery_percent = int(data.get("batteryPercent", box["battery_percent"]))
    battery_percent = min(100, max(0, battery_percent))
    firmware = str(data.get("firmwareVersion", box["firmware_version"]))

    db.execute(
        """
        UPDATE boxes
        SET is_locked = ?, has_package = ?, is_online = ?, battery_percent = ?,
            firmware_version = ?, last_seen_at = ?, updated_at = ?
        WHERE id = ?
        """,
        (is_locked, has_package, is_online, battery_percent, firmware, now, now, box_id),
    )

    if battery_percent < 15:
        existing = db.execute(
            """
            SELECT 1 FROM alerts
            WHERE box_id = ? AND severity = 'battery' AND acknowledged_at IS NULL
            """,
            (box_id,),
        ).fetchone()
        if existing is None:
            create_alert(
                db,
                box_id,
                {
                    "title": "Low battery warning",
                    "message": "Battery level is below 15%. Please recharge soon.",
                    "severity": "battery",
                },
            )

    return {"box": box_payload(db.execute("SELECT * FROM boxes WHERE id = ?", (box_id,)).fetchone())}
