from contextlib import asynccontextmanager
from http import HTTPStatus
from typing import Any

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from config import HOST, PORT
from db import ensure_database
from routes.auth_routes import router as auth_router
from routes.box_routes import router as box_router
from routes.embedded_routes import router as embedded_router
from services.box_service import api_index
from services.errors import ApiError
from services.time_service import iso_now


@asynccontextmanager
async def lifespan(_app: FastAPI):
    ensure_database()
    yield


app = FastAPI(title="Smart Drop-Off Box Backend", version="1.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST", "PATCH", "OPTIONS"],
    allow_headers=["Content-Type", "Authorization", "X-Device-Key"],
)


def error_response(status: int | HTTPStatus, message: str) -> JSONResponse:
    code = int(status)
    return JSONResponse({"error": {"code": code, "message": message}}, status_code=code)


@app.exception_handler(ApiError)
async def api_error_handler(_request: Request, exc: ApiError) -> JSONResponse:
    return error_response(exc.status, exc.message)


@app.exception_handler(RequestValidationError)
async def validation_error_handler(_request: Request, exc: RequestValidationError) -> JSONResponse:
    for error in exc.errors():
        if error.get("type") == "json_invalid":
            return error_response(HTTPStatus.BAD_REQUEST, "Invalid JSON body.")
    return error_response(HTTPStatus.BAD_REQUEST, "Invalid request.")


@app.exception_handler(StarletteHTTPException)
async def http_error_handler(_request: Request, exc: StarletteHTTPException) -> JSONResponse:
    message = "Endpoint not found." if exc.status_code == HTTPStatus.NOT_FOUND else str(exc.detail)
    return error_response(exc.status_code, message)


@app.exception_handler(Exception)
async def unexpected_error_handler(_request: Request, exc: Exception) -> JSONResponse:
    return error_response(HTTPStatus.INTERNAL_SERVER_ERROR, f"Unexpected server error: {exc}")


@app.get("/health")
def health() -> dict[str, Any]:
    return {"ok": True, "service": "smart-drop-off-box-backend", "time": iso_now()}


@app.get("/api")
def api() -> dict[str, Any]:
    return api_index()


app.include_router(auth_router)
app.include_router(box_router)
app.include_router(embedded_router)


def run() -> None:
    import uvicorn

    print(f"Smart Drop-Off Box backend running on http://{HOST}:{PORT}")
    print("Demo login: emir@example.com / 123456")
    uvicorn.run(app, host=HOST, port=PORT, reload=False)


if __name__ == "__main__":
    run()
