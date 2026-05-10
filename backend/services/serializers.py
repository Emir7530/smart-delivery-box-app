import json
import sqlite3
from datetime import datetime, timedelta
from typing import Any

from services.time_service import utc_now


def public_user(row: sqlite3.Row) -> dict[str, Any]:
    return {
        "id": row["id"],
        "fullName": row["full_name"],
        "email": row["email"],
        "phone": row["phone"],
        "createdAt": row["created_at"],
    }


def box_payload(row: sqlite3.Row) -> dict[str, Any]:
    return {
        "id": row["id"],
        "label": row["label"],
        "isLocked": bool(row["is_locked"]),
        "hasPackage": bool(row["has_package"]),
        "isOnline": bool(row["is_online"]),
        "batteryPercent": row["battery_percent"],
        "firmwareVersion": row["firmware_version"],
        "lastSeenAt": row["last_seen_at"],
        "updatedAt": row["updated_at"],
    }


def delivery_payload(row: sqlite3.Row) -> dict[str, Any]:
    delivered = datetime.fromisoformat(row["delivered_at"].replace("Z", "+00:00"))
    return {
        "id": row["id"],
        "orderNumber": row["order_number"],
        "status": row["status"],
        "deliveredAt": row["delivered_at"],
        "date": delivered.strftime("%b %d, %Y"),
        "time": delivered.strftime("%I:%M %p"),
        "note": row["note"],
        "packageKind": row["package_kind"],
        "otpUsed": row["otp_used"],
        "weight": f"{row['weight_kg']:.1f} kg",
        "imageUrl": row["image_url"],
    }


def alert_payload(row: sqlite3.Row) -> dict[str, Any]:
    return {
        "id": row["id"],
        "title": row["title"],
        "message": row["message"],
        "time": human_time(row["created_at"]),
        "severity": row["severity"],
        "attemptTimes": json.loads(row["attempt_times"] or "[]"),
        "createdAt": row["created_at"],
        "acknowledgedAt": row["acknowledged_at"],
    }


def command_payload(row: sqlite3.Row) -> dict[str, Any]:
    return {
        "id": row["id"],
        "boxId": row["box_id"],
        "command": row["command"],
        "status": row["status"],
        "requestedBy": row["requested_by"],
        "requestedAt": row["requested_at"],
        "completedAt": row["completed_at"],
    }


def human_time(timestamp: str) -> str:
    dt = datetime.fromisoformat(timestamp.replace("Z", "+00:00"))
    now = utc_now()
    if dt.date() == now.date():
        return dt.strftime("%I:%M %p")
    if dt.date() == (now - timedelta(days=1)).date():
        return "Yesterday, " + dt.strftime("%I:%M %p")
    return dt.strftime("%b %d, %Y")
