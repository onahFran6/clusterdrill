"""Core question engine + session mode web app.

FastAPI + server-rendered Jinja2 HTML + a light sprinkle of vanilla JS
(only for the "Check" button's fetch call and checklist DOM update). No SPA
framework, no build step.

Core question engine:
    - Task / Hint / Solution tabs (QUESTION.md, its Hint section, ANSWER.md)
    - Live per-criterion checklist wired to check.sh's real stdout
    - A "Reset" action (full_reset + setup.sh) so the UI is exercisable
      end-to-end.

Session mode (layered on top, see sessions.py):
    - A topic-lab landing page (`GET /topics`) listing pool sizes and mode
      availability.
    - Starting a session (`POST /sessions/start`) picks a concrete ordered
      qid list and makes it the single active session.
    - Question view navigation (Previous/Skip/progress bar/position) now
      walks the *active session's* list, not the full flat bank - see
      services/question_view.py's question_context() session-resolution
      logic and its documented fallback for a qid outside any active
      session.

Embedded terminal (see ttyd_manager.py):
    - A single long-lived `ttyd` subprocess, spawned on FastAPI startup and
      terminated on shutdown (see the `lifespan` handler below), embedded
      into question.html as an iframe. Bound to loopback only
      (127.0.0.1) - see ttyd_manager.py's module docstring for the full
      security rationale.
    - Purely additive UI surface: nothing in this file reads ttyd's output
      or wires it into check.sh's criteria in any way.

Diagram tab (see services/question_view.py's read_diagram_mmd() and
question_context()):
    - A fourth "Diagram" tab alongside Task/Hint/Solution. Content is read
      server-side (same pattern as QUESTION.md/ANSWER.md) and handed to
      Mermaid.js (loaded from a CDN in question.html) to render client-side
      into boxes/arrows - this file never renders Mermaid itself.

Grading integrity invariant: the only source of
PASS/FAIL/score data is check.sh's live stdout, parsed by grading_client.py.
There is no endpoint anywhere in this app that accepts a client-supplied
"mark as done" flag.

2026-08 restructure: this file used to hold every route plus ~450 lines of
question-page-building logic directly (1,292 lines total). Routes now live
in routers/ (one module per concern - pages, questions, sessions, auth,
idle, terminal, health), question-page context-building lives in
services/question_view.py, and the shared Jinja2Templates instance lives in
templating.py. This file is now just the app factory: lifespan, middleware
registration, router wiring, and the shared exception handler. Same
security_headers.py/auth.py/idle.py hardening pass also added CSRF
protection, a CSP, and WebSocket Origin validation - see those modules'
own docstrings.
"""
from __future__ import annotations

import asyncio
import logging
import os
from contextlib import asynccontextmanager

import auth
import rbac
import topology
import users
from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from idle import tracker as idle_tracker
from routers import (
    admin_router,
    auth_router,
    health,
    idle_router,
    pages,
    questions_router,
    sessions_router,
    terminal_router,
)
from security_headers import SecurityHeadersMiddleware
from sessions import store as session_store
from starlette.middleware.sessions import SessionMiddleware
from starlette.requests import Request
from templating import WEB_DIR, templates
from ttyd_manager import manager as ttyd_manager

from questions import bank

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("clusterdrill.app")

IDLE_WATCHDOG_INTERVAL_SECONDS = 15


async def _perform_idle_kill() -> None:
    """The actual idle-kill action, factored out of _idle_watchdog's loop so
    it's callable (and testable) on its own.

    Revokes access first - fast, pure-Python, and the actually
    time-sensitive part - before the slower tmux teardown.
    kill_all_tmux_sessions() does up to max_tabs sequential, synchronous
    `tmux kill-session` subprocess round-trips with no timeout; run
    directly on the watchdog's coroutine it would stall the single event
    loop this whole app runs on (every concurrent HTTP request, every
    terminal WS byte-pump) for the full duration. asyncio.to_thread
    offloads it, matching lifespan()'s own pattern for its one other
    blocking call (kubectl apply for CRDs).
    """
    logger.warning(
        "idle timeout reached (%.0fs with no activity) - killing terminal "
        "sessions and revoking the login cookie",
        idle_tracker.idle_seconds,
    )
    session_store.clear_all()
    auth.revoke_all_sessions()
    idle_tracker.mark_killed()
    await asyncio.to_thread(ttyd_manager.kill_all_tmux_sessions)


async def _idle_watchdog() -> None:
    """Background loop, not a one-shot timer per touch(), because
    idle_tracker's own kill_at deadline moves every time touch() fires - see
    idle.py. Only ever acts while the password gate is on: idle-kill is
    meaningless for local dev or an SSH-tunnel deployment, which already
    have their own trust boundary (your machine, your SSH key) and no login
    to revoke - see auth.py's module docstring for that same scoping
    decision applied to the gate itself."""
    while True:
        await asyncio.sleep(IDLE_WATCHDOG_INTERVAL_SECONDS)
        if not auth.password_gate_enabled():
            continue
        if idle_tracker.should_kill:
            await _perform_idle_kill()


@asynccontextmanager
async def lifespan(app: FastAPI):
    # The filter is established before any route can expose the bank. It is
    # deliberately derived from the in-cluster ServiceAccount, never a host
    # kubeconfig or a browser-provided value.
    bank.set_node_count(await asyncio.to_thread(topology.node_count))
    bank.set_storage_profile(await asyncio.to_thread(topology.storage_profile))
    # RBAC system namespace/ClusterRole first - kube_json.SYSTEM_NAMESPACE
    # must exist before anything below can write a ConfigMap/Secret into it,
    # including the account Secrets ensure_bootstrap_admin below writes.
    # Self-healing on every restart (e.g. after the namespace was wiped
    # independently of the account Secrets that reference it), not just at
    # account-creation time. Runs in a thread since it shells out;
    # best-effort (never raises) so a cluster that isn't reachable yet
    # degrades this app's cluster-dependent features for this run instead of
    # blocking startup. Unconditional (not single-user-mode-gated, unlike the
    # per-user ServiceAccount loop below) because account storage itself
    # lives in this namespace regardless of mode.
    await asyncio.to_thread(rbac.ensure_system_bootstrap)
    # One-time admin-account bootstrap from CLUSTERDRILL_PASSWORD
    # (see users.ensure_bootstrap_admin's docstring) - a no-op once any
    # account already exists. Runs after ensure_system_bootstrap so
    # SYSTEM_NAMESPACE is guaranteed to already exist.
    await asyncio.to_thread(users.ensure_bootstrap_admin)
    # An identity that can create ClusterRoleBindings can bind cluster-admin.
    # Local appliances therefore run in one-trusted-operator mode and never
    # provision shared-cluster terminal RBAC identities. Hosted multi-user
    # deployments must isolate each learner in a separate cluster.
    if not users.single_user_mode():
        # One ServiceAccount + kubeconfig per existing account - best-effort
        # per user, like everything else in this block - one account's
        # provisioning failure doesn't block the others or startup.
        for existing_user in await asyncio.to_thread(users.list_users):
            await asyncio.to_thread(rbac.ensure_user_service_account, existing_user.user_id)
    # Spawn the single app-lifetime ttyd process on startup, and
    # make sure it never survives the FastAPI process on shutdown (no
    # orphaned ttyd left running after the dev server stops).
    ttyd_manager.start()
    watchdog_task = asyncio.create_task(_idle_watchdog())
    try:
        yield
    finally:
        watchdog_task.cancel()
        ttyd_manager.stop()


app = FastAPI(title="ClusterDrill", lifespan=lifespan)
app.mount("/static", StaticFiles(directory=str(WEB_DIR / "static")), name="static")

# Session cookie (signed, itsdangerous-backed via Starlette) that
# auth.PasswordGateMiddleware reads/writes. Added unconditionally - it's a
# no-op storage layer when auth.password_gate_enabled() is False (the
# middleware itself short-circuits before ever touching request.session in
# that case, see auth.py). SESSION_SECRET must be set whenever the gate is
# actually enabled (CLUSTERDRILL_PASSWORD set) - falling back to a
# per-process random secret otherwise still works (cookies just stop
# validating across a restart, whether or not the gate is even on), so this
# never crashes local dev for lack of a secret.
#
# Starlette builds its middleware stack by wrapping in *reverse*
# registration order (see Starlette.build_middleware_stack), so the
# last-registered middleware ends up outermost and runs first per request.
# Registration order here, first to last (= innermost to outermost):
#   1. PasswordGateMiddleware  - needs request.session already populated
#   2. SessionMiddleware       - populates request.session
#   3. SecurityHeadersMiddleware - outermost, so its headers land on every
#      response including PasswordGateMiddleware's own redirects/errors
#
# Hard ceiling on the signed cookie's own lifetime, independent of the idle
# watchdog (idle.py/_idle_watchdog above) - defense in depth, not a
# duplicate of it. Starlette's SessionMiddleware enforces this server-side
# (itsdangerous's TimestampSigner rejects an expired signature outright),
# not just via the cookie's own browser-facing Max-Age attribute, so a
# replayed/copied cookie older than this is worthless regardless of what
# the client sends. Used to default to Starlette's own fallback (14 days)
# by simply never setting max_age - fine for a throwaway local dev cookie,
# not for one that can grant a live shell into a real cluster from anywhere
# on the internet.
SESSION_MAX_AGE_SECONDS = int(os.environ.get("CLUSTERDRILL_SESSION_MAX_AGE_SECONDS", 8 * 60 * 60))

app.add_middleware(auth.PasswordGateMiddleware)
app.add_middleware(
    SessionMiddleware,
    secret_key=os.environ.get("CLUSTERDRILL_SESSION_SECRET") or os.urandom(32).hex(),
    session_cookie="clusterdrill_session",
    same_site="lax",
    max_age=SESSION_MAX_AGE_SECONDS,
    https_only=False,  # Cloudflare Tunnel terminates TLS at the edge;
                       # the hop from cloudflared to this app is loopback-only, not
                       # public, so requiring HTTPS on this cookie would just break
                       # local dev/SSH-tunnel access for no additional protection.
)
app.add_middleware(SecurityHeadersMiddleware)


@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    """404s/500s from a page navigation get the app's own error page instead
    of FastAPI's raw JSON - a stale link (e.g. after content changes) should
    land somewhere with a way back in, not a bare {"detail": ...} dump. The
    Check/Reset endpoints are fetch()-driven JSON APIs, not navigations, so
    they keep the plain JSON error the frontend JS already expects."""
    if request.method == "GET" and "text/html" in request.headers.get("accept", ""):
        return templates.TemplateResponse(
            request,
            "error.html",
            {"status_code": exc.status_code, "detail": exc.detail},
            status_code=exc.status_code,
        )
    return JSONResponse(status_code=exc.status_code, content={"detail": exc.detail})


app.include_router(pages.router)
app.include_router(questions_router.router)
app.include_router(sessions_router.router)
app.include_router(auth_router.router)
app.include_router(admin_router.router)
app.include_router(idle_router.router)
app.include_router(terminal_router.router)
app.include_router(health.router)
