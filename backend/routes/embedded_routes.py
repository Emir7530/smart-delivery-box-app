from http import HTTPStatus
from typing import Any

from fastapi import APIRouter, Body, Depends
from fastapi.responses import JSONResponse

from auth.dependencies import require_device_key
from db import session
from services.alert_service import create_alert
from services.box_service import get_box
from services.command_service import complete_command, list_pending_commands
from services.delivery_service import create_delivery
from services.event_service import EVENTS
from services.otp_service import verify_otp
from services.rate_limit_service import check_rate_limit
from services.serializers import box_payload
from services.telemetry_service import update_telemetry


router = APIRouter(prefix="/api/boxes/{box_id}/embedded", dependencies=[Depends(require_device_key)])


@router.get("/commands")
def commands(box_id: str) -> dict[str, Any]:
    with session() as db:
        get_box(db, box_id)
        return list_pending_commands(db, box_id)


@router.post("/commands/{command_id}/complete")
def complete(
    box_id: str,
    command_id: str,
    payload: dict[str, Any] = Body(default_factory=dict),
) -> dict[str, Any]:
    with session() as db:
        get_box(db, box_id)
        command = complete_command(db, box_id, command_id, payload)
        db.commit()
        EVENTS.publish(box_id, "command.completed", command)
        return {"command": command, "box": box_payload(get_box(db, box_id))}


@router.post("/telemetry")
def telemetry(box_id: str, payload: dict[str, Any] = Body(default_factory=dict)) -> dict[str, Any]:
    with session() as db:
        get_box(db, box_id)
        result = update_telemetry(db, box_id, payload)
        db.commit()
        EVENTS.publish(box_id, "box.updated", result["box"])
        return result


@router.post("/delivery")
def delivery(box_id: str, payload: dict[str, Any] = Body(default_factory=dict)) -> JSONResponse:
    with session() as db:
        get_box(db, box_id)
        delivery_payload = create_delivery(db, box_id, payload)
        db.commit()
        EVENTS.publish(box_id, "delivery.created", delivery_payload)
        return JSONResponse({"delivery": delivery_payload}, status_code=HTTPStatus.CREATED)


@router.post("/alerts")
def alerts(box_id: str, payload: dict[str, Any] = Body(default_factory=dict)) -> JSONResponse:
    with session() as db:
        get_box(db, box_id)
        alert = create_alert(db, box_id, payload)
        db.commit()
        EVENTS.publish(box_id, "alert.created", alert)
        return JSONResponse({"alert": alert}, status_code=HTTPStatus.CREATED)


@router.post("/otp/verify")
def otp_verify(
    box_id: str,
    payload: dict[str, Any] = Body(default_factory=dict),
) -> dict[str, Any]:
    check_rate_limit("otp", box_id, limit=5, window_seconds=300)
    with session() as db:
        get_box(db, box_id)
        result = verify_otp(db, box_id, payload)
        db.commit()
        EVENTS.publish(box_id, "otp.verified", result)
        return result
