import secrets
import sqlite3
from typing import Any

from services.otp_service import current_otp
from services.serializers import delivery_payload
from services.time_service import iso_now


def create_delivery(db: sqlite3.Connection, box_id: str, data: dict[str, Any]) -> dict[str, Any]:
    now = iso_now()
    max_order = db.execute(
        "SELECT COALESCE(MAX(order_number), 0) AS max_order FROM deliveries WHERE box_id = ?",
        (box_id,),
    ).fetchone()["max_order"]
    otp_used = str(data.get("otpUsed", "")).strip() or current_otp(db, box_id)["code"]
    delivery_id = "delivery-" + secrets.token_hex(8)
    db.execute(
        """
        INSERT INTO deliveries
        (id, box_id, order_number, status, delivered_at, note, package_kind, otp_used, weight_kg, image_url)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            delivery_id,
            box_id,
            int(max_order) + 1,
            str(data.get("status", "Delivered")),
            str(data.get("deliveredAt", now)),
            str(data.get("note", "Package detected by sensor and logged.")),
            str(data.get("packageKind", "cardboard")),
            otp_used,
            float(data.get("weightKg", 0.0)),
            data.get("imageUrl"),
        ),
    )
    db.execute("UPDATE boxes SET has_package = 1, updated_at = ? WHERE id = ?", (now, box_id))
    return delivery_payload(db.execute("SELECT * FROM deliveries WHERE id = ?", (delivery_id,)).fetchone())
