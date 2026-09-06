"""Login/logout routes - extracted from app.py's original monolith
(2026-08 restructure) with no behavior change, just a new home.

Reachable pre-login (see auth._PUBLIC_PATHS). No-ops in the sense that if
auth.password_gate_enabled() is False, PasswordGateMiddleware never
redirects here in the first place - hitting /login directly in that mode
just shows a login form that, once submitted, sets a session flag nothing
ever checks. Harmless, but only reachable at all in the disabled state if
someone navigates here manually.
"""
from __future__ import annotations

import auth
from fastapi import APIRouter, Depends, Form
from fastapi.responses import RedirectResponse
from idle import tracker as idle_tracker
from services.question_view import base_context
from starlette.requests import Request
from templating import templates

router = APIRouter()


@router.get("/login")
def login_form(request: Request, next: str = "/topics"):
    return templates.TemplateResponse(
        request, "login.html",
        {**base_context(request), "next": auth.safe_next_path(next), "error": False},
    )


@router.post("/login")
def login_submit(
    request: Request,
    username: str = Form(...),
    password: str = Form(...),
    next: str = Form("/topics"),
):
    safe_next = auth.safe_next_path(next)

    # Atomic check-and-record (auth.check_lockout_and_record_attempt) -
    # not a separate seconds_until_unlocked() + record_failed_login() pair,
    # which had a real TOCTOU gap between the two lock acquisitions. See
    # that function's docstring. Still keyed by client IP, not by username
    # - a lockout scoped per-username would let an attacker try
    # unlimited passwords against *other* accounts from one IP by just
    # rotating the username field; keeping it IP-keyed caps total guesses
    # from one source regardless of which account they're aimed at.
    lockout_seconds = auth.check_lockout_and_record_attempt(request)
    if lockout_seconds is not None:
        return templates.TemplateResponse(
            request, "login.html",
            {**base_context(request), "next": safe_next, "error": True, "lockout_seconds": lockout_seconds},
            status_code=429,
        )

    if auth.attempt_login(request, username, password) is not None:
        auth.clear_login_attempts(request)
        # A fresh login is, definitionally, a human present right now -
        # starts the idle clock over rather than inheriting whatever it was
        # counting down from before this login (e.g. right after the
        # watchdog itself forced this re-login).
        idle_tracker.touch()
        return RedirectResponse(url=safe_next, status_code=303)

    # No separate record_failed_login() call here - this attempt was
    # already recorded up front by check_lockout_and_record_attempt(),
    # unconditionally, before the password was even checked (see that
    # function's docstring for why that's correct: a successful login
    # already clears it via clear_login_attempts() above).
    return templates.TemplateResponse(
        request, "login.html",
        {**base_context(request), "next": safe_next, "error": True},
        status_code=401,
    )


@router.post("/logout", dependencies=[Depends(auth.csrf_protect_form)])
def logout_submit(request: Request):
    auth.logout(request)
    return RedirectResponse(url="/login", status_code=303)
