#!/usr/bin/env python3
"""Compatibility entrypoint for the FastAPI backend.

The backend now lives in ``app.py`` and the modules below it. This file keeps
the historical ``python backend/server.py`` workflow working.
"""

from app import run


if __name__ == "__main__":
    run()
