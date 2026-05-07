# Smart Drop-Off Box Backend

This backend was added for the Flutter-only prototype in `mobile_app/`.
It follows the project proposal flow: mobile app auth, box state, OTP,
delivery history, security alerts, and ESP32 command/telemetry exchange.

The proposal mentions Firebase Auth + Firebase Realtime Database. This local
backend keeps the same concepts, but runs with only Python standard library so
the team can test the mobile app and ESP32 flow before moving the schema to
Firebase.

## Run

```bash
python backend/server.py
```

On this WSL-based repo, the safest command is:

```bash
cd /home/masud/DropBox/smart-delivery-box-app
python3 backend/server.py
```

Defaults:

- Base URL: `http://127.0.0.1:8080`
- Demo account: `emir@example.com`
- Demo password: `123456`
- Demo box id: `box-demo-001`
- ESP32 device key: `esp32-demo-key`
- SQLite file: `backend/data/smart_box.sqlite3`

Environment variables:

```bash
SMART_BOX_HOST=0.0.0.0
SMART_BOX_PORT=8080
SMART_BOX_SECRET=change-this-secret
SMART_BOX_DEVICE_KEY=esp32-real-device-key
SMART_BOX_DB=backend/data/smart_box.sqlite3
```

## Mobile API

Send `Authorization: Bearer <token>` after login/register.

```http
POST /api/auth/register
POST /api/auth/login
GET  /api/me
GET  /api/boxes/{boxId}/snapshot
GET  /api/boxes/{boxId}/state
GET  /api/boxes/{boxId}/otp
POST /api/boxes/{boxId}/otp/regenerate
POST /api/boxes/{boxId}/commands
GET  /api/boxes/{boxId}/commands
GET  /api/boxes/{boxId}/deliveries
GET  /api/boxes/{boxId}/alerts
GET  /api/boxes/{boxId}/events
```

Login:

```bash
curl -X POST http://127.0.0.1:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"emir@example.com\",\"password\":\"123456\"}"
```

Lock/unlock command:

```bash
curl -X POST http://127.0.0.1:8080/api/boxes/box-demo-001/commands \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d "{\"command\":\"unlock\"}"
```

## ESP32 API

Send `X-Device-Key: esp32-demo-key` from the embedded system.

```http
GET  /api/boxes/{boxId}/embedded/commands
POST /api/boxes/{boxId}/embedded/commands/{commandId}/complete
POST /api/boxes/{boxId}/embedded/telemetry
POST /api/boxes/{boxId}/embedded/delivery
POST /api/boxes/{boxId}/embedded/alerts
POST /api/boxes/{boxId}/embedded/otp/verify
```

Telemetry example:

```bash
curl -X POST http://127.0.0.1:8080/api/boxes/box-demo-001/embedded/telemetry \
  -H "Content-Type: application/json" \
  -H "X-Device-Key: esp32-demo-key" \
  -d "{\"isLocked\":true,\"hasPackage\":false,\"isOnline\":true,\"batteryPercent\":74,\"firmwareVersion\":\"esp32-prototype-0.1\"}"
```

Delivery example:

```bash
curl -X POST http://127.0.0.1:8080/api/boxes/box-demo-001/embedded/delivery \
  -H "Content-Type: application/json" \
  -H "X-Device-Key: esp32-demo-key" \
  -d "{\"weightKg\":2.1,\"packageKind\":\"cardboard\",\"imageUrl\":\"https://example.com/delivery.jpg\"}"
```

## Firebase Mapping

When switching to Firebase, map the tables to these Realtime Database nodes:

```text
users/{uid}
boxes/{boxId}
boxes/{boxId}/commands/{commandId}
boxes/{boxId}/deliveries/{deliveryId}
boxes/{boxId}/alerts/{alertId}
boxes/{boxId}/otps/{otpId}
```

The same payload fields are camelCase so Flutter can consume them directly.
Use `firebase.rules.json` as the first security-rules draft for the Firebase
Realtime Database version.

## Flutter Notes

- Android emulator base URL: `http://10.0.2.2:8080`
- iOS simulator / desktop / web base URL: `http://127.0.0.1:8080`
- Physical phone base URL: use the computer's LAN IP and run the backend with
  `SMART_BOX_HOST=0.0.0.0`.
