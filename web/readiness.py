"""Tracks whether this process's startup cluster sweep has finished (R10).

A separate module, not a flag on app.py itself, so health.py's /readyz
route (and anything else that needs to ask "has the sweep run yet") can
import this without importing app.py - app.py already imports health.py's
router, so the reverse would be circular.
"""
from __future__ import annotations

_sweep_complete = False


def mark_sweep_complete() -> None:
    global _sweep_complete
    _sweep_complete = True


def sweep_complete() -> bool:
    return _sweep_complete
