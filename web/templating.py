"""Shared Jinja2Templates instance - a true leaf module (no app-specific
imports), imported by every router that renders an HTML page plus app.py's
own exception handler. Kept separate from services/question_view.py because
routers with nothing to do with question-view logic (auth_router.py,
health.py) still need to render a template (login.html, error.html).
"""
from __future__ import annotations

from pathlib import Path

from fastapi.templating import Jinja2Templates

WEB_DIR = Path(__file__).resolve().parent
templates = Jinja2Templates(directory=str(WEB_DIR / "templates"))
