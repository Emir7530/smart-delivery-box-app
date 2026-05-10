from pathlib import Path
import os


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
