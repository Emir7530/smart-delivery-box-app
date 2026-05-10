import threading
import time
from typing import Any

from auth.token import json_dumps
from services.time_service import iso_now


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


def sse_lines(box_id: str, last_event_id: int):
    events = EVENTS.wait_after(last_event_id)
    if not events:
        yield ": keep-alive\n\n"
        return

    for event in events:
        if event["boxId"] != box_id:
            continue
        yield f"id: {event['id']}\n"
        yield f"event: {event['type']}\n"
        yield "data: "
        yield json_dumps(event).decode()
        yield "\n\n"
