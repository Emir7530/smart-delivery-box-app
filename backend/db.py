import json
import sqlite3
from contextlib import contextmanager
from datetime import timedelta
from typing import Iterator

from auth.security import hash_password
from config import DATA_DIR, DB_PATH, DEFAULT_BOX_ID, DEVICE_KEY, OTP_TTL_SECONDS
from services.device_service import create_device_key, ensure_demo_device_key
from services.time_service import iso_now, utc_now


def connect() -> sqlite3.Connection:
    db = sqlite3.connect(DB_PATH)
    db.row_factory = sqlite3.Row
    return db


@contextmanager
def session() -> Iterator[sqlite3.Connection]:
    db = connect()
    try:
        yield db
    finally:
        db.close()


def ensure_database() -> None:
    DATA_DIR.mkdir(exist_ok=True)
    with session() as db:
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

            CREATE TABLE IF NOT EXISTS device_keys (
              id TEXT PRIMARY KEY,
              box_id TEXT NOT NULL,
              key_hash TEXT NOT NULL,
              label TEXT NOT NULL,
              created_at TEXT NOT NULL,
              revoked_at TEXT,
              FOREIGN KEY(box_id) REFERENCES boxes(id)
            );
            """
        )
        migrate_device_keys(db)
        seed_demo_data(db)
        ensure_existing_boxes_have_device_keys(db)


def migrate_device_keys(db: sqlite3.Connection) -> None:
    columns = {
        row["name"]
        for row in db.execute("PRAGMA table_info(device_keys)").fetchall()
    }
    if "revoked_at" not in columns:
        db.execute("ALTER TABLE device_keys ADD COLUMN revoked_at TEXT")


def ensure_existing_boxes_have_device_keys(db: sqlite3.Connection) -> None:
    for row in db.execute("SELECT id FROM boxes").fetchall():
        ensure_demo_device_key(db, row["id"])
    db.commit()


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
    create_device_key(db, DEFAULT_BOX_ID, DEVICE_KEY, "Demo ESP32")

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
