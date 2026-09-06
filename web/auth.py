"""App-level password gate, in front of the web app AND the embedded
terminal.

Only relevant once this app is reachable beyond localhost or an SSH
tunnel - e.g. once a public tunnel or reverse proxy is put in front of it.
Disabled entirely (no-op middleware, no login page) unless
CLUSTERDRILL_PASSWORD is set in the environment, so local dev
(practice-bank/web's normal `uvicorn app:app`) and an SSH-tunnel
deployment are completely unaffected - both already rely on a trust
boundary (your own machine, or your own SSH key) that doesn't need a
second password layered on top.

Login checks a username+password against users.py's per-user accounts
instead of comparing against one literal shared secret - see
attempt_login(). CLUSTERDRILL_PASSWORD keeps its original job as the
on/off switch for whether login is required at all
(password_gate_enabled()); it also doubles, once and only once, as the seed
password for an auto-created "admin" account (users.ensure_bootstrap_admin)
so an existing single-shared-password deployment isn't locked out of its
own app by this upgrade.

Design:
    - Session-cookie gate via Starlette's SessionMiddleware (itsdangerous
      signed cookies - tamper-evident, not just base64). No server-side
      session store; the cookie carries the login flag plus which user_id
      logged in.
    - Gates *every* route by default, including the terminal, since
      question.html's terminal iframe is proxied through this same FastAPI
      app (see app.py's /terminal/{path:path} route) rather than hitting
      ttyd's port directly - one auth boundary covers both surfaces, and
      ttyd's own port never needs a separate tunnel ingress or its own
      password check.
    - Explicit allowlist for what must stay reachable pre-login: the login
      page itself, the static assets it needs to render (unstyled login
      page would be a bad first impression but is not a security bug -
      excluded for polish, not safety), and /healthz (so infra tooling can
      health-check without a cookie).
"""
from __future__ import annotations

import hmac
import os
import secrets
import threading
import time
from typing import Optional

import users
from fastapi import Form, HTTPException
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import RedirectResponse, Response

SESSION_KEY = "clusterdrill_authed"
# Wall-clock timestamp stamped into the cookie at login (attempt_login),
# never touched again after that - see session_is_valid() and
# revoke_all_sessions() below for what it's for.
AUTHED_AT_KEY = "clusterdrill_authed_at"
# Which user account this cookie belongs to - the authoritative
# identity for anything authorization-sensitive (see current_user()); never
# trust USERNAME_KEY/IS_ADMIN_KEY below for that, they're display-only
# caches of what was true at login time.
USER_ID_KEY = "clusterdrill_user_id"
# Cached at login purely so templates can show "logged in as X" and the nav
# can decide whether to show the Admin link, without a kubectl round-trip
# on every single page render. Can go stale if an operator renames a user
# or revokes their admin flag mid-session - harmless for display, and never
# used to actually gate the /admin routes themselves (see
# routers/admin_router.py's use of require_admin, which looks the user back
# up live).
USERNAME_KEY = "clusterdrill_username"
IS_ADMIN_KEY = "clusterdrill_is_admin_hint"
# CSRF token, stamped once per login alongside the keys above - see the
# "CSRF protection" section further down for issuance/validation.
CSRF_SESSION_KEY = "clusterdrill_csrf_token"

# Paths (or prefixes) reachable without a session cookie. Kept minimal and
# explicit on purpose - anything not listed here requires login, including
# every /terminal/* path.
_PUBLIC_PATHS = {"/login", "/healthz"}
_PUBLIC_PREFIXES = ("/static/",)

# Fetch()-driven JSON endpoints (see PasswordGateMiddleware.dispatch): these
# get a 401 the calling JS can react to (idle.py's client-side poller
# redirects itself to /login) instead of a 303 redirect, which a background
# fetch() would just silently follow and never surface to the user. This is
# the ONLY thing this list is for now - CSRF enforcement used to also key
# off it (a second, independent reason for a route to be in this tuple) but
# that coupling is exactly what let /sessions/end ship with no CSRF check:
# it's a JSON endpoint but was never added here, and there was no other
# signal that it needed to be. CSRF is now a per-route FastAPI dependency
# (csrf_protect_header/csrf_protect_form below) declared at the route
# itself, with tests/test_csrf_coverage.py enforcing that every mutating
# route either has one or is in that test's explicit, justified exemption
# list - a structural check, not a second list to remember to update here.
_JSON_ENDPOINT_SUFFIXES = ("/check", "/reset", "/heartbeat", "/idle-status")

# -----------------------------------------------------------------------------
# Revocation: a way to force a cookie to require a fresh login without
# touching the signing secret (which would also nuke in-flight state
# elsewhere). Two flavors:
#   - revoke_all_sessions(): everyone re-logs in. Used by app.py's idle
#     watchdog (idle.py) when nobody has touched the keyboard for too long -
#     killing the tmux sessions alone isn't enough, since a client could
#     otherwise reconnect and get a fresh tmux session under the same
#     still-valid cookie. Still genuinely global even with multiple
#     accounts: the watchdog has no way to know *which* account has been
#     idle without per-user activity tracking, which is a known future
#     limitation, not implemented yet.
#   - revoke_user_sessions(user_id): just the one account. Used by
#     routers/admin_router.py after an admin deletes a user or resets their
#     password - the other, unaffected users shouldn't be forced to
#     re-login too.
# In-memory only (module-level dict/float, reset on process restart) - same
# tradeoff sessions.py/idle.py/ttyd_manager.py already make; a restart
# already invalidates every cookie by construction (the app.py `SECRET_KEY`
# fallback in a restart, or simply because there's nothing left to compare
# against until the first revoke), so losing this state on restart isn't a
# meaningful bypass.
# -----------------------------------------------------------------------------
_revoked_before = 0.0
_revoked_before_by_user: dict[str, float] = {}


def revoke_all_sessions() -> None:
    global _revoked_before
    _revoked_before = time.time()


def revoke_user_sessions(user_id: str) -> None:
    _revoked_before_by_user[user_id] = time.time()


def session_is_valid(session: dict) -> bool:
    """True only for a cookie that (a) actually logged in, (b) carries a
    user_id, and (c) did so after the
    last revoke_all_sessions()/revoke_user_sessions(that user) call."""
    if session.get(SESSION_KEY) is not True:
        return False
    authed_at = session.get(AUTHED_AT_KEY)
    if not isinstance(authed_at, (int, float)):
        return False
    user_id = session.get(USER_ID_KEY)
    if not isinstance(user_id, str) or not user_id:
        return False
    if authed_at <= _revoked_before:
        return False
    if authed_at <= _revoked_before_by_user.get(user_id, 0.0):
        return False
    return True


def current_user_id(session: dict) -> Optional[str]:
    return session.get(USER_ID_KEY)


def current_username(session: dict) -> Optional[str]:
    return session.get(USERNAME_KEY)


def current_user(request: Request) -> Optional["users.User"]:
    """Live lookup (one kubectl round-trip), not the cookie's cached
    username/is_admin-hint - the authoritative source for anything
    authorization-sensitive, like require_admin() below. Only called from
    the rarely-hit /admin routes, never from per-request middleware, so
    that cost is acceptable here - see USER_ID_KEY/IS_ADMIN_KEY's docstring
    for why the cached hint isn't good enough for that."""
    user_id = current_user_id(request.session)
    if not user_id:
        return None
    return users.get_user(user_id)


def require_admin(request: Request) -> Optional["users.User"]:
    """FastAPI dependency gating routers/admin_router.py. A no-op (like
    csrf_protect_header/csrf_protect_form below) when the password gate
    itself is disabled - local dev and an SSH-tunnel deployment have no
    login flow at all in that mode, so there's no session to check an
    is_admin flag against; the existing trust boundary (your own machine,
    your own SSH key) already covers the admin page too."""
    if not password_gate_enabled():
        return None
    user = current_user(request)
    if user is None or not user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required.")
    return user


# -----------------------------------------------------------------------------
# Login rate limiting: this app sits behind a single shared password once
# it's reachable on a public URL (see this module's docstring) - with
# no throttling, that password is just an offline-speed brute-force target
# from anywhere on the internet. Keyed by client IP (best-effort - see
# _client_key), in-memory, matching every other piece of state in this app
# (single-process, resets on restart - fine, a restart is a rare enough
# event that losing lockout state isn't a meaningful bypass).
# -----------------------------------------------------------------------------
_LOGIN_MAX_ATTEMPTS = 5
_LOGIN_WINDOW_SECONDS = 15 * 60
_LOGIN_LOCKOUT_SECONDS = 15 * 60

_login_failures: dict[str, list[float]] = {}
_login_lock = threading.Lock()


def _client_key(request: Request) -> str:
    """Prefer the header Cloudflare Tunnel sets for the real client IP
    (`cf-connecting-ip`) over request.client.host, which is always the
    tunnel daemon's own loopback address once a Cloudflare Tunnel is in
    front of this app - without this every visitor would share one
    lockout bucket. Falls back through the generic X-Forwarded-For header
    for other reverse proxies, then the raw socket peer for local dev or
    an SSH-tunnel deployment, neither of which go through a proxy at
    all."""
    return (
        request.headers.get("cf-connecting-ip")
        or request.headers.get("x-forwarded-for", "").split(",")[0].strip()
        or (request.client.host if request.client else "unknown")
    )


def seconds_until_unlocked(request: Request) -> Optional[int]:
    """None if this client can attempt a login right now; otherwise how many
    seconds until it can again. Also prunes attempts older than the window
    so this dict doesn't grow unbounded across a long-running process."""
    key = _client_key(request)
    now = time.time()
    with _login_lock:
        attempts = [t for t in _login_failures.get(key, []) if now - t < _LOGIN_WINDOW_SECONDS]
        _login_failures[key] = attempts
        if len(attempts) < _LOGIN_MAX_ATTEMPTS:
            return None
        oldest_counted = attempts[-_LOGIN_MAX_ATTEMPTS]
        remaining = int(_LOGIN_LOCKOUT_SECONDS - (now - oldest_counted))
        return remaining if remaining > 0 else None


def record_failed_login(request: Request) -> None:
    key = _client_key(request)
    with _login_lock:
        _login_failures.setdefault(key, []).append(time.time())


def check_lockout_and_record_attempt(request: Request) -> Optional[int]:
    """Atomically checks whether this client is already locked out and, if
    not, records this login attempt against the window - both under one
    lock acquisition. Use this from the actual /login route instead of
    calling seconds_until_unlocked() followed by a separate
    record_failed_login() call: that two-call shape has a real TOCTOU gap,
    since the lock is released between the check and the record. Under
    concurrent requests from the same attacker, several could all pass the
    check (each still seeing the count under _LOGIN_MAX_ATTEMPTS) before
    any of them got around to recording its own attempt - a burst of
    concurrent guesses could slip past the 5-attempt threshold before it
    closed. seconds_until_unlocked()/record_failed_login() stay separate,
    unmutated functions (still directly useful for tests, and for anything
    that only needs to peek at lockout state without recording an
    attempt) - this is the one place both need to be atomic together.

    Recording unconditionally - including for what turns out to be a
    correct password - is safe: login_submit already calls
    clear_login_attempts() on a successful login, which wipes this back
    out, so nothing changes for the success path.

    Returns lockout seconds remaining if this client is already locked out
    (nothing recorded this call); None if the attempt was recorded and may
    proceed.
    """
    key = _client_key(request)
    now = time.time()
    with _login_lock:
        attempts = [t for t in _login_failures.get(key, []) if now - t < _LOGIN_WINDOW_SECONDS]
        if len(attempts) >= _LOGIN_MAX_ATTEMPTS:
            oldest_counted = attempts[-_LOGIN_MAX_ATTEMPTS]
            remaining = int(_LOGIN_LOCKOUT_SECONDS - (now - oldest_counted))
            if remaining > 0:
                _login_failures[key] = attempts
                return remaining
        attempts.append(now)
        _login_failures[key] = attempts
        return None


def clear_login_attempts(request: Request) -> None:
    key = _client_key(request)
    with _login_lock:
        _login_failures.pop(key, None)


def password_gate_enabled() -> bool:
    """Whether the gate is active at all. False (fully disabled, no-op) for
    local dev and an SSH-tunnel deployment, where CLUSTERDRILL_PASSWORD
    is simply never set - see this module's docstring. This env var still
    means "require login", separately from its other
    job as the bootstrap-admin seed (users.ensure_bootstrap_admin)."""
    return bool(os.environ.get("CLUSTERDRILL_PASSWORD"))


def _is_public(path: str) -> bool:
    if path in _PUBLIC_PATHS:
        return True
    return any(path.startswith(prefix) for prefix in _PUBLIC_PREFIXES)


class PasswordGateMiddleware(BaseHTTPMiddleware):
    """Redirects any request without a valid session cookie to /login.
    Installed unconditionally in app.py, but becomes a pure pass-through
    (dispatches straight to call_next) when password_gate_enabled() is
    False, so there is zero behavior change for local dev / SSH-tunnel use."""

    async def dispatch(self, request: Request, call_next):
        if not password_gate_enabled():
            return await call_next(request)

        if _is_public(request.url.path):
            return await call_next(request)

        if session_is_valid(request.session):
            # CSRF is enforced per-route now (csrf_protect_header/
            # csrf_protect_form below, wired in as FastAPI dependencies on
            # each mutating route) - not here. See _JSON_ENDPOINT_SUFFIXES'
            # comment for why that coupling was removed.
            return await call_next(request)

        # Fetch()-driven JSON endpoints (Check/Reset/heartbeat/idle-status)
        # get a 401 they can surface/react to in JS rather than a redirect
        # their fetch() call would just silently follow; everything else
        # (page navigations, the terminal proxy) redirects to the login page
        # with a return-to hint. Checked by suffix regardless of method so a
        # GET poll (idle-status) and a POST action (heartbeat/check/reset)
        # are both covered the same way.
        if request.url.path.endswith(_JSON_ENDPOINT_SUFFIXES):
            return Response(
                status_code=401,
                content='{"detail":"Not authenticated. Reload and log in."}',
                media_type="application/json",
            )

        next_path = request.url.path
        if request.url.query:
            next_path += f"?{request.url.query}"
        return RedirectResponse(url=f"/login?next={next_path}", status_code=303)


def attempt_login(request: Request, username: str, password: str) -> Optional["users.User"]:
    """Sets the session cookie (authed-at timestamp, user_id, the display-
    only username/is_admin-hint caches, and a fresh CSRF token - see the
    CSRF section above) on success. Returns the matched User (truthy) so
    the /login route can decide what to render, or None on a bad
    username/password."""
    user = users.authenticate(username, password)
    if user is None:
        return None
    request.session[SESSION_KEY] = True
    request.session[AUTHED_AT_KEY] = time.time()
    request.session[USER_ID_KEY] = user.user_id
    request.session[USERNAME_KEY] = user.username
    request.session[IS_ADMIN_KEY] = user.is_admin
    request.session[CSRF_SESSION_KEY] = secrets.token_urlsafe(32)
    return user


def logout(request: Request) -> None:
    request.session.pop(SESSION_KEY, None)
    request.session.pop(AUTHED_AT_KEY, None)
    request.session.pop(USER_ID_KEY, None)
    request.session.pop(USERNAME_KEY, None)
    request.session.pop(IS_ADMIN_KEY, None)
    request.session.pop(CSRF_SESSION_KEY, None)


# -----------------------------------------------------------------------------
# CSRF protection: one token per login, stamped into the same signed session
# cookie as SESSION_KEY/AUTHED_AT_KEY (attempt_login below) - not a
# double-submit-cookie pattern, since this app is explicitly single-active-
# user, so there is only ever one session's token to track.
#
# Structural, not conventional: every mutating route declares ONE of the two
# dependencies below directly in its route decorator
# (`dependencies=[Depends(auth.csrf_protect_header)]` or
# `...csrf_protect_form`) - there is no separate list anywhere that has to
# stay in sync with the route table (the previous version of this code had
# exactly that: a URL-suffix allowlist in middleware, and /sessions/end
# shipped without ever being added to it - a real bug, not hypothetical).
# tests/test_csrf_coverage.py walks every registered route and asserts this
# structurally: any POST/PUT/PATCH/DELETE route must carry one of these two
# dependencies or be in that test's small, explicitly-justified exemption
# list. A new mutating route that forgets CSRF protection now fails a test,
# not just a code review.
#
# Two dependency flavors, not one, because they read the token from
# different places:
#   - csrf_protect_header: JSON/fetch endpoints - reads X-CSRF-Token,
#     header-only, never touches the request body.
#   - csrf_protect_form: real <form> POSTs - reads a csrf_token form field
#     via FastAPI's own Form(...) parameter injection. Deliberately not
#     read via request.form() in a shared header-style check: a
#     BaseHTTPMiddleware (or a dependency) that manually awaits
#     request.form() risks double-consuming the body stream against the
#     route handler's own Form(...) parameters depending on framework
#     version - letting FastAPI's dependency injection own the one read is
#     what avoids that entirely.
#
# Login itself is deliberately not CSRF-protected: before login there is no
# session to abuse. A CSRF'd POST to /login just rides the victim's own
# browser into submitting an attacker-chosen password guess, blind (the
# attacker never sees the response) - it lands on the victim's own IP-based
# rate limit (seconds_until_unlocked/record_failed_login above), never an
# actual bypass or credential leak. Not worth defending against - /login is
# in test_csrf_coverage.py's exemption list with this same reasoning.
# -----------------------------------------------------------------------------


def get_csrf_token(request: Request) -> str:
    return request.session.get(CSRF_SESSION_KEY, "")


def _csrf_matches(request: Request, supplied: str) -> bool:
    expected = get_csrf_token(request)
    return bool(expected) and hmac.compare_digest(expected, supplied)


def csrf_protect_header(request: Request) -> None:
    """FastAPI dependency - attach via
    `dependencies=[Depends(csrf_protect_header)]` on any fetch()-driven
    JSON route. No-op when the gate is disabled or the session isn't valid
    yet (PasswordGateMiddleware already rejects the latter before this
    would ever run in practice; checked again here so this dependency is
    safe to reason about in isolation, e.g. in a test)."""
    if not password_gate_enabled() or not session_is_valid(request.session):
        return
    if not _csrf_matches(request, request.headers.get("x-csrf-token", "")):
        raise HTTPException(status_code=403, detail="CSRF validation failed.")


def require_csrf_form(request: Request, csrf_token: str) -> None:
    """The actual form-CSRF check, factored out so csrf_protect_form (the
    dependency routes should actually use) and any direct caller share one
    comparison. No-op when the password gate is disabled (local
    dev/SSH-tunnel) - no login ever happens in that mode, so no token is
    ever issued to compare against, and CSRF isn't a meaningful threat
    within that already-established trust boundary."""
    if not password_gate_enabled():
        return
    if not _csrf_matches(request, csrf_token):
        raise HTTPException(status_code=403, detail="CSRF validation failed.")


def csrf_protect_form(request: Request, csrf_token: Optional[str] = Form(None)) -> None:
    """FastAPI dependency - attach via
    `dependencies=[Depends(csrf_protect_form)]` on any real <form> POST
    route. The field is optional at the request-parser level because an
    intentionally password-free localhost deployment does not mint one.
    It remains mandatory whenever the password gate is on: require_csrf_form
    rejects an absent value exactly as it rejects a wrong value."""
    require_csrf_form(request, csrf_token or "")


def safe_next_path(raw: Optional[str]) -> str:
    """Only ever redirect within this app after login - an open redirect via
    ?next= is exactly the kind of thing a security review (this ticket's own
    explicit requirement) should catch, so it's closed here rather than left
    for that review to find.

    Also rejects /logout specifically: it's a POST-only route (CSRF-protected
    logout action), so a plain GET redirect there 405s. Found the hard way -
    an expired session (or clicking "Log out" itself) sets next=/logout, and
    logging back in then bounces straight into that 405 page, which looks
    exactly like the login failed even though it actually succeeded."""
    if not raw or not raw.startswith("/") or raw.startswith("//") or raw == "/logout":
        return "/topics"
    return raw
