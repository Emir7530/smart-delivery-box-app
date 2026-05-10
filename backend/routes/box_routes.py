from contextlib import contextmanager
from http import HTTPStatus
from typing import Any

from fastapi import APIRouter, Body, Depends, Query
from fastapi.responses import JSONResponse, StreamingResponse

from auth.dependencies import require_user_id
from db import session
from services import box_service
from services.command_service import create_command
from services.event_service import EVENTS, sse_lines
from services.otp_service import create_otp, current_otp
from services.serializers import box_payload


router = APIRouter(prefix="/api/boxes")


@contextmanager
def _require_access(box_id: str, user_id: str):
    with session() as db:
        box_service.require_box_access(db, box_id, user_id)
        yield db


@router.get("/{box_id}/state")
def state(box_id: str, user_id: str = Depends(require_user_id)) -> dict[str, Any]:
    with _require_access(box_id, user_id) as db:
        return box_service.get_box_state(db, box_id)


@router.get("/{box_id}/snapshot")
def snapshot(box_id: str, user_id: str = Depends(require_user_id)) -> dict[str, Any]:
    with _require_access(box_id, user_id) as db:
        return box_service.box_snapshot(db, box_id)


@router.get("/{box_id}/otp")
def otp(box_id: str, user_id: str = Depends(require_user_id)) -> dict[str, Any]:
    with _require_access(box_id, user_id) as db:
        return {"otp": current_otp(db, box_id)}


@router.post("/{box_id}/otp/regenerate")
def regenerate_otp(box_id: str, user_id: str = Depends(require_user_id)) -> JSONResponse:
    with _require_access(box_id, user_id) as db:
        otp_payload = create_otp(db, box_id)
        db.commit()
        EVENTS.publish(box_id, "otp.updated", otp_payload)
        return JSONResponse({"otp": otp_payload}, status_code=HTTPStatus.CREATED)


@router.get("/{box_id}/commands")
def commands(box_id: str, user_id: str = Depends(require_user_id)) -> dict[str, Any]:
    with _require_access(box_id, user_id) as db:
        return box_service.list_commands(db, box_id)


@router.post("/{box_id}/commands")
def create_box_command(
    box_id: str,
    payload: dict[str, Any] = Body(default_factory=dict),
    user_id: str = Depends(require_user_id),
) -> JSONResponse:
    with _require_access(box_id, user_id) as db:
        command = create_command(db, box_id, user_id, payload)
        db.commit()
        EVENTS.publish(box_id, "command.created", command)
        box = box_payload(box_service.get_box(db, box_id))
        return JSONResponse({"command": command, "box": box}, status_code=HTTPStatus.CREATED)


@router.get("/{box_id}/deliveries")
def deliveries(box_id: str, user_id: str = Depends(require_user_id)) -> dict[str, Any]:
    with _require_access(box_id, user_id) as db:
        return box_service.list_deliveries(db, box_id)


@router.get("/{box_id}/alerts")
def alerts(box_id: str, user_id: str = Depends(require_user_id)) -> dict[str, Any]:
    with _require_access(box_id, user_id) as db:
        return box_service.list_alerts(db, box_id)


@router.get("/{box_id}/events")
def events(
    box_id: str,
    last_event_id: int = Query(default=0, alias="lastEventId"),
    user_id: str = Depends(require_user_id),
) -> StreamingResponse:
    with _require_access(box_id, user_id):
        pass
    return StreamingResponse(
        sse_lines(box_id, last_event_id),
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "Connection": "keep-alive"},
    )
