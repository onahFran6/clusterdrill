"""Structural CSRF coverage check - the actual fix for the /sessions/end
bug this test suite is named after finding.

Before this, CSRF enforcement for JSON/fetch routes was a URL-suffix
allowlist in auth.py's middleware, entirely decoupled from the route
table - a route could be added, or a route's CSRF requirement could be
lost in a refactor, with nothing to notice. /sessions/end shipped that way
for one whole session before a code review caught it by hand.

This test makes that failure mode structural instead of a matter of
remembering: it walks every registered route and asserts any mutating
(POST/PUT/PATCH/DELETE) route either declares one of auth.py's two CSRF
dependencies (csrf_protect_header or csrf_protect_form) or is in the
EXEMPT set below with a real, written reason. Add a new mutating route
without CSRF protection and without adding it here (with a justification
a reviewer can push back on) - this test fails.
"""
from __future__ import annotations

import auth
from app import app

_MUTATING_METHODS = {"POST", "PUT", "PATCH", "DELETE"}

# (path, method) -> reason. Every entry here is a route this test would
# otherwise flag - keep this list short and each reason concrete, not a
# rubber stamp.
EXEMPT = {
    ("/login", "POST"): (
        "No session exists yet to protect - a CSRF'd guess just rides the "
        "victim's own browser into their own IP-based rate limit "
        "(auth.seconds_until_unlocked), never an actual bypass or "
        "credential leak. See auth.py's CSRF section docstring."
    ),
    ("/terminal/t/{tab_id}/{path:path}", "POST"): (
        "Raw byte-proxy pass-through to ttyd, not a discrete "
        "server-side state change CSRF terms apply to - already gated by "
        "PasswordGateMiddleware's session check, and the WebSocket "
        "sibling route has its own Origin-based CSWSH defense "
        "(terminal_router._origin_is_trusted). This HTTP path exists for "
        "ttyd's own asset/API requests, not user-initiated actions."
    ),
    ("/terminal/t/{tab_id}/{path:path}", "PUT"): (
        "Same reasoning as the POST entry above - proxy pass-through."
    ),
    ("/terminal/{path:path}", "POST"): (
        "Legacy tab-1 alias of /terminal/t/{tab_id}/{path:path} - same "
        "reasoning as that route's entries."
    ),
    ("/terminal/{path:path}", "PUT"): (
        "Legacy tab-1 alias - same reasoning as /terminal/t/... PUT."
    ),
}

_CSRF_DEPENDENCIES = {auth.csrf_protect_header, auth.csrf_protect_form}


def _flatten_routes(routes):
    # FastAPI >=0.130-ish wraps include_router()'d routes in a lazy
    # _IncludedRouter instead of copying them into app.routes directly -
    # unwrap via its (public-named) original_router to reach the real
    # Route objects. Duck-typed rather than isinstance-checked against the
    # private _IncludedRouter class so this keeps working across FastAPI
    # versions that do flatten eagerly (original_router just won't exist on
    # those route objects). Without this, _mutating_routes() below silently
    # yields nothing on newer FastAPI and both tests in this file pass
    # vacuously - checking zero routes, not the routes that actually exist.
    for r in routes:
        nested = getattr(r, "original_router", None)
        if nested is not None:
            yield from _flatten_routes(nested.routes)
        else:
            yield r


def _mutating_routes():
    for route in _flatten_routes(app.routes):
        methods = getattr(route, "methods", None)
        if not methods or not (methods & _MUTATING_METHODS):
            continue
        for method in methods & _MUTATING_METHODS:
            yield route, method


def test_every_mutating_route_is_csrf_protected_or_explicitly_exempt():
    unprotected = []
    for route, method in _mutating_routes():
        if (route.path, method) in EXEMPT:
            continue
        dependant = getattr(route, "dependant", None)
        dep_calls = {d.call for d in dependant.dependencies} if dependant else set()
        if not (dep_calls & _CSRF_DEPENDENCIES):
            unprotected.append(f"{method} {route.path}")

    assert not unprotected, (
        "Mutating route(s) with no CSRF dependency and no EXEMPT entry: "
        f"{unprotected}. Add dependencies=[Depends(auth.csrf_protect_header)] "
        "(fetch/JSON routes) or dependencies=[Depends(auth.csrf_protect_form)] "
        "(real <form> POSTs) to the route, or add a justified EXEMPT entry "
        "in this file if the route genuinely doesn't need it."
    )


def test_exempt_entries_still_point_at_real_routes():
    # Catches the opposite drift: a route in EXEMPT that got renamed/removed,
    # silently leaving a stale, unverifiable justification behind.
    real_routes = {(route.path, method) for route, method in _mutating_routes()}
    stale = set(EXEMPT) - real_routes
    assert not stale, f"EXEMPT entries no longer matching a real route: {stale}"
