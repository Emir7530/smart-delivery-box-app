import time
from collections import defaultdict, deque
from http import HTTPStatus

from services.errors import ApiError


_attempts: dict[str, deque[float]] = defaultdict(deque)


def check_rate_limit(bucket: str, key: str, *, limit: int, window_seconds: int) -> None:
    now = time.time()
    attempt_key = f"{bucket}:{key}"
    attempts = _attempts[attempt_key]
    while attempts and attempts[0] <= now - window_seconds:
        attempts.popleft()
    if len(attempts) >= limit:
        raise ApiError(HTTPStatus.TOO_MANY_REQUESTS, "Too many attempts. Please try again later.")
    attempts.append(now)
