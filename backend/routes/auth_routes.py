from http import HTTPStatus
from typing import Any

from fastapi import APIRouter, Body, Depends, Request
from fastapi.responses import JSONResponse

from auth.dependencies import require_user_id
from db import session
from services.auth_service import login as login_user
from services.auth_service import register as register_user
from services.box_service import get_user
from services.rate_limit_service import check_rate_limit
from services.serializers import public_user


router = APIRouter(prefix="/api")


@router.post("/auth/register")
def register(payload: dict[str, Any] = Body(default_factory=dict)) -> JSONResponse:
    with session() as db:
        return JSONResponse(register_user(db, payload), status_code=HTTPStatus.CREATED)


@router.post("/auth/login")
def login(request: Request, payload: dict[str, Any] = Body(default_factory=dict)) -> dict[str, Any]:
    email = str(payload.get("email", "")).strip().lower()
    client = request.client.host if request.client else "unknown"
    check_rate_limit("login", f"{client}:{email}", limit=5, window_seconds=60)
    with session() as db:
        return login_user(db, payload)


@router.get("/me")
def me(user_id: str = Depends(require_user_id)) -> dict[str, Any]:
    with session() as db:
        return {"user": public_user(get_user(db, user_id))}
