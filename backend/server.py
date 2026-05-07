#!/usr/bin/env python3
"""Smart Drop-Off Box prototype backend.

This service mirrors the Firebase-style backend described in the project
proposal while staying runnable with only the Python standard library.
"""

from __future__ import annotations

import base64
import hashlib
import hmac
import json
import os
import secrets
import signal
import sqlite3
import threading
import time
from datetime import datetime, timedelta, timezone
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any
from urllib.parse import parse_qs, urlparse


BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data"
DB_PATH = Path(os.getenv("SMART_BOX_DB", DATA_DIR / "smart_box.sqlite3"))
HOST = os.getenv("SMART_BOX_HOST", "127.0.0.1")
PORT = int(os.getenv("SMART_BOX_PORT", "8080"))
JWT_SECRET = os.getenv("SMART_BOX_SECRET", "dev-secret-change-me")
DEVICE_KEY = os.getenv("SMART_BOX_DEVICE_KEY", "esp32-demo-key")
TOKEN_TTL_SECONDS = 60 * 60 * 24 * 7
OTP_TTL_SECONDS = 5 * 60
DEFAULT_BOX_ID = "box-demo-001"


class ApiError(Exception):
    def __init__(self, status: HTTPStatus, message: str):
        super().__init__(message)
        self.status = status
        self.message = message


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def iso_now() -> str:
    return utc_now().replace(microsecond=0).isoformat().replace("+00:00", "Z")


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


def hash_password(password: str, salt: str | None = None) -> tuple[str, str]:
    salt = salt or secrets.token_hex(16)
    digest = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode(),
        bytes.fromhex(salt),
        120_000,
    )
    return salt, digest.hex()


def check_password(password: str, salt: str, password_hash: str) -> bool:
    _, candidate = hash_password(password, salt)
    return hmac.compare_digest(candidate, password_hash)


def otp_code() -> str:
    raw = f"{secrets.randbelow(1_000_000):06d}"
    return f"{raw[:3]} {raw[3:]}"


def ensure_database() -> None:
    DATA_DIR.mkdir(exist_ok=True)
    with connect() as db:
        db.executescript(
            """
            PRAGMA foreign_keys = ON;

            CREATE TABLE IF NOT EXISTS users (
              id TEXT PRIMARY KEY,
              full_name TEXT NOT NULL,
              email TEXT NOT NULL UNIQUE,
              phone TEXT NOT NULL,
              password_salt TEXT NOT NULL,
              password_hash TEXT NOT NULL,
              created_at TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS boxes (
              id TEXT PRIMARY KEY,
              owner_user_id TEXT NOT NULL,
              label TEXT NOT NULL,
              is_locked INTEGER NOT NULL,
              has_package INTEGER NOT NULL,
              is_online INTEGER NOT NULL,
              battery_percent INTEGER NOT NULL,
              firmware_version TEXT NOT NULL,
              last_seen_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY(owner_user_id) REFERENCES users(id)
            );

            CREATE TABLE IF NOT EXISTS otps (
              id TEXT PRIMARY KEY,
              box_id TEXT NOT NULL,
              code TEXT NOT NULL,
              expires_at TEXT NOT NULL,
              used_at TEXT,
              created_at TEXT NOT NULL,
              FOREIGN KEY(box_id) REFERENCES boxes(id)
            );

            CREATE TABLE IF NOT EXISTS commands (
              id TEXT PRIMARY KEY,
              box_id TEXT NOT NULL,
              command TEXT NOT NULL,
              status TEXT NOT NULL,
              requested_by TEXT NOT NULL,
              requested_at TEXT NOT NULL,
              completed_at TEXT,
              FOREIGN KEY(box_id) REFERENCES boxes(id),
              FOREIGN KEY(requested_by) REFERENCES users(id)
            );

            CREATE TABLE IF NOT EXISTS deliveries (
              id TEXT PRIMARY KEY,
              box_id TEXT NOT NULL,
              order_number INTEGER NOT NULL,
              status TEXT NOT NULL,
              delivered_at TEXT NOT NULL,
              note TEXT NOT NULL,
              package_kind TEXT NOT NULL,
              otp_used TEXT NOT NULL,
              weight_kg REAL NOT NULL,
              image_url TEXT,
              FOREIGN KEY(box_id) REFERENCES boxes(id)
            );

            CREATE TABLE IF NOT EXISTS alerts (
              id TEXT PRIMARY KEY,
              box_id TEXT NOT NULL,
              title TEXT NOT NULL,
              message TEXT NOT NULL,
              severity TEXT NOT NULL,
              attempt_times TEXT NOT NULL DEFAULT '[]',
              created_at TEXT NOT NULL,
              acknowledged_at TEXT,
              FOREIGN KEY(box_id) REFERENCES boxes(id)
            );
            """
        )
        seed_demo_data(db)


def connect() -> sqlite3.Connection:
    db = sqlite3.connect(DB_PATH)
    db.row_factory = sqlite3.Row
    return db


def seed_demo_data(db: sqlite3.Connection) -> None:
    user_exists = db.execute("SELECT 1 FROM users LIMIT 1").fetchone()
    if user_exists:
        return

    user_id = "user-demo-001"
    salt, password_hash = hash_password("123456")
    now = iso_now()
    db.execute(
        """
        INSERT INTO users (id, full_name, email, phone, password_salt, password_hash, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        """,
        (user_id, "Emir Kaldırımcı", "emir@example.com", "05551234567", salt, password_hash, now),
    )
    db.execute(
        """
        INSERT INTO boxes
        (id, owner_user_id, label, is_locked, has_package, is_online, battery_percent,
         firmware_version, last_seen_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (DEFAULT_BOX_ID, user_id, "Smart Drop-Off Box", 1, 0, 1, 10, "esp32-prototype-0.1", now, now),
    )

    expires = (utc_now() + timedelta(seconds=OTP_TTL_SECONDS)).replace(microsecond=0)
    db.execute(
        """
        INSERT INTO otps (id, box_id, code, expires_at, used_at, created_at)
        VALUES (?, ?, ?, ?, NULL, ?)
        """,
        ("otp-demo-001", DEFAULT_BOX_ID, "482 759", expires.isoformat().replace("+00:00", "Z"), now),
    )

    deliveries = [
        ("delivery-003", 3, "Delivered", "2026-05-24T10:30:00Z", "View photo, OTP used, and details", "cardboard", "482 759", 2.4),
        ("delivery-002", 2, "Delivered", "2026-05-22T13:45:00Z", "View photo, OTP used, and details", "mailer", "174 908", 0.7),
        ("delivery-001", 1, "Delivered", "2026-05-20T11:05:00Z", "View photo, OTP used, and details", "cardboardAlt", "690 221", 1.8),
    ]
    db.executemany(
        """
        INSERT INTO deliveries
        (id, box_id, order_number, status, delivered_at, note, package_kind, otp_used, weight_kg, image_url)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NULL)
        """,
        [(item[0], DEFAULT_BOX_ID, *item[1:]) for item in deliveries],
    )

    alerts = [
        ("alert-003", "Low battery warning", "Battery level is below 15%. Please recharge soon.", "battery", [], "2026-05-06T23:32:00Z"),
        ("alert-002", "Unauthorized access attempt", "Someone tried to access the box without authorization.", "critical", [], "2026-05-07T02:14:00Z"),
        ("alert-001", "Wrong OTP entered", "3 failed attempts", "warning", ["02:02 AM", "02:01 AM", "01:59 AM"], "2026-05-07T02:02:00Z"),
    ]
    db.executemany(
        """
        INSERT INTO alerts
        (id, box_id, title, message, severity, attempt_times, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        """,
        [
            (alert_id, DEFAULT_BOX_ID, title, message, severity, json.dumps(attempts), created_at)
            for alert_id, title, message, severity, attempts, created_at in alerts
        ],
    )
    db.commit()


class EventHub:
    def __init__(self) -> None:
        self._condition = threading.Condition()
        self._events: list[dict[str, Any]] = []

    def publish(self, box_id: str, event_type: str, payload: dict[str, Any]) -> None:
        with self._condition:
            self._events.append(
                {
                    "id": len(self._events) + 1,
                    "boxId": box_id,
                    "type": event_type,
                    "payload": payload,
                    "createdAt": iso_now(),
                }
            )
            self._events = self._events[-200:]
            self._condition.notify_all()

    def wait_after(self, last_id: int, timeout: float = 20) -> list[dict[str, Any]]:
        deadline = time.time() + timeout
        with self._condition:
            while True:
                events = [event for event in self._events if event["id"] > last_id]
                if events:
                    return events
                remaining = deadline - time.time()
                if remaining <= 0:
                    return []
                self._condition.wait(remaining)


EVENTS = EventHub()


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


def require_fields(data: dict[str, Any], fields: list[str]) -> None:
    missing = [field for field in fields if not str(data.get(field, "")).strip()]
    if missing:
        raise ApiError(HTTPStatus.BAD_REQUEST, f"Missing required field(s): {', '.join(missing)}.")


def normalize_email(email: str) -> str:
    return email.strip().lower()


def validate_phone(phone: str) -> None:
    if len(phone) != 11 or not phone.startswith("0") or not phone.isdigit():
        raise ApiError(HTTPStatus.BAD_REQUEST, "Phone number must start with 0 and be 11 digits.")


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


class SmartBoxHandler(BaseHTTPRequestHandler):
    server_version = "SmartBoxBackend/1.0"

    def do_OPTIONS(self) -> None:
        self.send_response(HTTPStatus.NO_CONTENT)
        self.cors_headers()
        self.end_headers()

    def do_GET(self) -> None:
        self.handle_request("GET")

    def do_POST(self) -> None:
        self.handle_request("POST")

    def do_PATCH(self) -> None:
        self.handle_request("PATCH")

    def handle_request(self, method: str) -> None:
        try:
            parsed = urlparse(self.path)
            path = parsed.path.rstrip("/") or "/"
            query = parse_qs(parsed.query)

            if method == "GET" and path == "/health":
                self.respond({"ok": True, "service": "smart-drop-off-box-backend", "time": iso_now()})
                return

            if method == "GET" and path == "/api":
                self.respond(api_index())
                return

            if method == "POST" and path == "/api/auth/register":
                self.register()
                return

            if method == "POST" and path == "/api/auth/login":
                self.login()
                return

            if method == "GET" and path == "/api/me":
                user_id = self.require_user_id()
                with connect() as db:
                    user = self.get_user(db, user_id)
                    self.respond({"user": public_user(user)})
                return

            if path.startswith("/api/boxes/"):
                self.route_box(method, path, query)
                return

            raise ApiError(HTTPStatus.NOT_FOUND, "Endpoint not found.")
        except ApiError as exc:
            self.respond_error(exc.status, exc.message)
        except json.JSONDecodeError:
            self.respond_error(HTTPStatus.BAD_REQUEST, "Invalid JSON body.")
        except Exception as exc:  # pragma: no cover - keeps prototype server resilient.
            self.respond_error(HTTPStatus.INTERNAL_SERVER_ERROR, f"Unexpected server error: {exc}")

    def route_box(self, method: str, path: str, query: dict[str, list[str]]) -> None:
        parts = path.split("/")
        if len(parts) < 4:
            raise ApiError(HTTPStatus.NOT_FOUND, "Endpoint not found.")

        box_id = parts[3]
        tail = parts[4:]

        if tail == ["events"] and method == "GET":
            self.stream_events(box_id, query)
            return

        if tail and tail[0] == "embedded":
            self.route_embedded(method, box_id, tail[1:])
            return

        user_id = self.require_user_id()
        with connect() as db:
            self.require_box_access(db, box_id, user_id)

            if tail == ["state"] and method == "GET":
                box = self.get_box(db, box_id)
                self.respond({"box": box_payload(box)})
                return

            if tail == ["snapshot"] and method == "GET":
                self.respond(box_snapshot(db, box_id))
                return

            if tail == ["otp"] and method == "GET":
                self.respond({"otp": current_otp(db, box_id)})
                return

            if tail == ["otp", "regenerate"] and method == "POST":
                otp = create_otp(db, box_id)
                db.commit()
                EVENTS.publish(box_id, "otp.updated", otp)
                self.respond({"otp": otp}, HTTPStatus.CREATED)
                return

            if tail == ["commands"] and method == "GET":
                rows = db.execute(
                    "SELECT * FROM commands WHERE box_id = ? ORDER BY requested_at DESC LIMIT 20",
                    (box_id,),
                ).fetchall()
                self.respond({"commands": [command_payload(row) for row in rows]})
                return

            if tail == ["commands"] and method == "POST":
                command = self.create_command(db, box_id, user_id)
                db.commit()
                EVENTS.publish(box_id, "command.created", command)
                self.respond({"command": command, "box": box_payload(self.get_box(db, box_id))}, HTTPStatus.CREATED)
                return

            if tail == ["deliveries"] and method == "GET":
                rows = db.execute(
                    "SELECT * FROM deliveries WHERE box_id = ? ORDER BY delivered_at DESC",
                    (box_id,),
                ).fetchall()
                self.respond({"deliveries": [delivery_payload(row) for row in rows]})
                return

            if tail == ["alerts"] and method == "GET":
                rows = db.execute(
                    "SELECT * FROM alerts WHERE box_id = ? ORDER BY created_at DESC",
                    (box_id,),
                ).fetchall()
                self.respond({"alerts": [alert_payload(row) for row in rows]})
                return

            raise ApiError(HTTPStatus.NOT_FOUND, "Endpoint not found.")

    def route_embedded(self, method: str, box_id: str, tail: list[str]) -> None:
        self.require_device_key()
        with connect() as db:
            self.get_box(db, box_id)

            if tail == ["commands"] and method == "GET":
                rows = db.execute(
                    """
                    SELECT * FROM commands
                    WHERE box_id = ? AND status = 'pending'
                    ORDER BY requested_at ASC
                    """,
                    (box_id,),
                ).fetchall()
                self.respond({"commands": [command_payload(row) for row in rows]})
                return

            if len(tail) == 3 and tail[0] == "commands" and tail[2] == "complete" and method == "POST":
                command = complete_command(db, box_id, tail[1], self.read_json())
                db.commit()
                EVENTS.publish(box_id, "command.completed", command)
                self.respond({"command": command, "box": box_payload(self.get_box(db, box_id))})
                return

            if tail == ["telemetry"] and method == "POST":
                payload = update_telemetry(db, box_id, self.read_json())
                db.commit()
                EVENTS.publish(box_id, "box.updated", payload["box"])
                self.respond(payload)
                return

            if tail == ["delivery"] and method == "POST":
                delivery = create_delivery(db, box_id, self.read_json())
                db.commit()
                EVENTS.publish(box_id, "delivery.created", delivery)
                self.respond({"delivery": delivery}, HTTPStatus.CREATED)
                return

            if tail == ["alerts"] and method == "POST":
                alert = create_alert(db, box_id, self.read_json())
                db.commit()
                EVENTS.publish(box_id, "alert.created", alert)
                self.respond({"alert": alert}, HTTPStatus.CREATED)
                return

            if tail == ["otp", "verify"] and method == "POST":
                result = verify_otp(db, box_id, self.read_json())
                db.commit()
                EVENTS.publish(box_id, "otp.verified", result)
                self.respond(result)
                return

            raise ApiError(HTTPStatus.NOT_FOUND, "Endpoint not found.")

    def register(self) -> None:
        data = self.read_json()
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

        with connect() as db:
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
            db.commit()

            user = self.get_user(db, user_id)
            self.respond(auth_response(user, db), HTTPStatus.CREATED)

    def login(self) -> None:
        data = self.read_json()
        require_fields(data, ["email", "password"])
        email = normalize_email(str(data["email"]))
        password = str(data["password"]).strip()

        with connect() as db:
            user = db.execute("SELECT * FROM users WHERE email = ?", (email,)).fetchone()
            if user is None or not check_password(password, user["password_salt"], user["password_hash"]):
                raise ApiError(HTTPStatus.UNAUTHORIZED, "No account matches those credentials.")
            self.respond(auth_response(user, db))

    def create_command(self, db: sqlite3.Connection, box_id: str, user_id: str) -> dict[str, Any]:
        data = self.read_json()
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

        # Prototype behavior: immediately reflect the requested state for the mobile UI.
        db.execute(
            """
            UPDATE boxes
            SET is_locked = ?, updated_at = ?
            WHERE id = ?
            """,
            (1 if command == "lock" else 0, now, box_id),
        )
        return command_payload(db.execute("SELECT * FROM commands WHERE id = ?", (command_id,)).fetchone())

    def stream_events(self, box_id: str, query: dict[str, list[str]]) -> None:
        user_id = self.require_user_id()
        with connect() as db:
            self.require_box_access(db, box_id, user_id)
        last_id = int((query.get("lastEventId") or ["0"])[0])
        self.send_response(HTTPStatus.OK)
        self.cors_headers()
        self.send_header("Content-Type", "text/event-stream")
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Connection", "keep-alive")
        self.end_headers()

        events = EVENTS.wait_after(last_id)
        if not events:
            self.wfile.write(b": keep-alive\n\n")
            return
        for event in events:
            if event["boxId"] != box_id:
                continue
            self.wfile.write(f"id: {event['id']}\n".encode())
            self.wfile.write(f"event: {event['type']}\n".encode())
            self.wfile.write(b"data: ")
            self.wfile.write(json_dumps(event))
            self.wfile.write(b"\n\n")

    def require_user_id(self) -> str:
        auth = self.headers.get("Authorization", "")
        if not auth.startswith("Bearer "):
            raise ApiError(HTTPStatus.UNAUTHORIZED, "Missing bearer token.")
        payload = verify_token(auth.removeprefix("Bearer ").strip())
        return str(payload["sub"])

    def require_device_key(self) -> None:
        if self.headers.get("X-Device-Key") != DEVICE_KEY:
            raise ApiError(HTTPStatus.UNAUTHORIZED, "Invalid device key.")

    def require_box_access(self, db: sqlite3.Connection, box_id: str, user_id: str) -> None:
        box = db.execute(
            "SELECT 1 FROM boxes WHERE id = ? AND owner_user_id = ?",
            (box_id, user_id),
        ).fetchone()
        if box is None:
            raise ApiError(HTTPStatus.NOT_FOUND, "Box not found for this user.")

    def get_user(self, db: sqlite3.Connection, user_id: str) -> sqlite3.Row:
        user = db.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
        if user is None:
            raise ApiError(HTTPStatus.UNAUTHORIZED, "User not found.")
        return user

    def get_box(self, db: sqlite3.Connection, box_id: str) -> sqlite3.Row:
        box = db.execute("SELECT * FROM boxes WHERE id = ?", (box_id,)).fetchone()
        if box is None:
            raise ApiError(HTTPStatus.NOT_FOUND, "Box not found.")
        return box

    def read_json(self) -> dict[str, Any]:
        length = int(self.headers.get("Content-Length", "0"))
        if length == 0:
            return {}
        return json.loads(self.rfile.read(length))

    def respond(self, payload: dict[str, Any], status: HTTPStatus = HTTPStatus.OK) -> None:
        body = json_dumps(payload)
        self.send_response(status)
        self.cors_headers()
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def respond_error(self, status: HTTPStatus, message: str) -> None:
        self.respond({"error": {"code": status.value, "message": message}}, status)

    def cors_headers(self) -> None:
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET,POST,PATCH,OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type,Authorization,X-Device-Key")

    def log_message(self, format: str, *args: Any) -> None:
        print(f"{self.log_date_time_string()} {self.address_string()} {format % args}")


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


def box_snapshot(db: sqlite3.Connection, box_id: str) -> dict[str, Any]:
    return {
        "box": box_payload(db.execute("SELECT * FROM boxes WHERE id = ?", (box_id,)).fetchone()),
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


def verify_otp(db: sqlite3.Connection, box_id: str, data: dict[str, Any]) -> dict[str, Any]:
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


def run() -> None:
    ensure_database()
    server = ThreadingHTTPServer((HOST, PORT), SmartBoxHandler)

    def shutdown(_signum: int, _frame: Any) -> None:
        threading.Thread(target=server.shutdown, daemon=True).start()

    signal.signal(signal.SIGINT, shutdown)
    signal.signal(signal.SIGTERM, shutdown)
    print(f"Smart Drop-Off Box backend running on http://{HOST}:{PORT}")
    print("Demo login: emir@example.com / 123456")
    server.serve_forever()


if __name__ == "__main__":
    run()
