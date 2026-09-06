"""Idle lifecycle: real cluster-access heartbeat/status - extracted from
app.py's original monolith (2026-08 restructure) with no behavior change,
just a new home.

See idle.py's module docstring for why this is a separate concept from
sessions.py's practice-session tracking. /heartbeat is the only thing that
counts as "the user is here" from page activity (the terminal's own
keystrokes count too - see routers/terminal_router.py's
_pump_client_to_upstream); static/app.js calls it from real, throttled
mouse/keyboard/scroll/touch events only, so polling /idle-status on a timer
can never masquerade as activity.
"""
from __future__ import annotations

import auth
from fastapi import APIRouter, Depends
from fastapi.responses import JSONResponse
from idle import tracker as idle_tracker

router = APIRouter()


def _idle_status_payload() -> dict:
    if not auth.password_gate_enabled():
        return {"enabled": False}
    return {
        "enabled": True,
        "warn_at": idle_tracker.warn_at,
        "kill_at": idle_tracker.kill_at,
        "killed": idle_tracker.killed_at is not None,
    }


@router.post("/heartbeat", dependencies=[Depends(auth.csrf_protect_header)])
def heartbeat():
    idle_tracker.touch()
    return JSONResponse(_idle_status_payload())


@router.get("/idle-status")
def idle_status():
    return JSONResponse(_idle_status_payload())
