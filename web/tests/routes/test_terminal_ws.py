"""WebSocket Origin validation (routers/terminal_router.py's
_origin_is_trusted) - the CSWSH defense added alongside the CSP/CSRF
hardening pass. Uses Starlette's TestClient (sync) rather than the
httpx.AsyncClient `client` fixture used elsewhere in tests/routes/, since
httpx has no WebSocket support - see the plan this was built from.

Deliberately never enters TestClient as a context manager (`with
TestClient(app) as tc`) - that triggers the app's real ASGI lifespan
startup, which calls profile_store.ensure_crds_installed() (a real
`kubectl apply`, blocked by tests/conftest.py's safety net, which would
fail the test outright) and ttyd_manager.start(). None of that is needed
here: websocket routing works without lifespan ever having run, and
_origin_is_trusted() is checked before the route touches ttyd_manager at
all. A plain TestClient(app) instance still handles requests/websockets
fine - lifespan is a separate ASGI protocol from http/websocket handling.

Never actually reaches a real ttyd either way (not running in the test
environment) - these tests only need to prove the Origin check itself
fires (or doesn't) before anything past it is reached, so a rejection at
the next stage (ttyd unavailable) is an equally valid "Origin check didn't
block it" signal.
"""
from __future__ import annotations

import inspect

import pytest
import ttyd_manager
from app import app
from starlette.routing import WebSocketRoute
from starlette.testclient import TestClient
from starlette.websockets import WebSocketDisconnect

WS_PATH = "/terminal/t/1/ws"

# Structural WS-auth coverage (routers/terminal_router.reject_unless_authorized):
# Starlette has no middleware equivalent for WebSocket connections, so
# there's no dependency-injection-based check like tests/test_csrf_coverage.py
# uses for HTTP routes - this does the closest available thing, source-text
# inspection, which is a blunter instrument but still catches "a WS route's
# handler never calls the shared auth check at all." A route that instead
# delegates to another WS route's handler (rather than calling
# reject_unless_authorized directly) must be listed here, naming what it
# delegates to, so the test can verify the *real* handler in the chain does
# the check - matches test_csrf_coverage.py's EXEMPT-with-a-reason pattern.
_DELEGATES_TO = {
    "/terminal/{path:path}": "/terminal/t/{tab_id}/{path:path}",
}


def _flatten_routes(routes):
    # FastAPI >=0.130-ish wraps include_router()'d routes in a lazy
    # _IncludedRouter instead of copying them into app.routes directly -
    # unwrap via its (public-named) original_router to reach the real
    # Route/WebSocketRoute objects. Duck-typed rather than isinstance-checked
    # against the private _IncludedRouter class so this keeps working across
    # FastAPI versions that do flatten eagerly (original_router just won't
    # exist on those route objects).
    for r in routes:
        nested = getattr(r, "original_router", None)
        if nested is not None:
            yield from _flatten_routes(nested.routes)
        else:
            yield r


def test_every_websocket_route_enforces_auth_directly_or_via_a_documented_delegate():
    ws_routes = {r.path: r for r in _flatten_routes(app.routes) if isinstance(r, WebSocketRoute)}
    assert ws_routes, "expected at least one WebSocket route to check"

    for path, route in ws_routes.items():
        src = inspect.getsource(route.endpoint)
        if "reject_unless_authorized" in src:
            continue
        delegate_path = _DELEGATES_TO.get(path)
        assert delegate_path is not None, (
            f"WebSocket route {path!r} never calls "
            "terminal_router.reject_unless_authorized() and isn't listed in "
            "_DELEGATES_TO - a route with no auth/origin check at all."
        )
        delegate_route = ws_routes.get(delegate_path)
        assert delegate_route is not None, (
            f"{path!r}'s _DELEGATES_TO entry ({delegate_path!r}) isn't a "
            "real registered WebSocket route"
        )
        delegate_src = inspect.getsource(delegate_route.endpoint)
        assert "reject_unless_authorized" in delegate_src, (
            f"{path!r} delegates to {delegate_path!r}, but that route's own "
            "handler doesn't call reject_unless_authorized() either"
        )


@pytest.fixture
def tc(monkeypatch):
    # Real ttyd happens to be installed on some dev machines (it is on the
    # one this suite was written on) - ensure_tab would otherwise actually
    # spawn it (tests/conftest.py's safety net correctly blocks the
    # tmux/ttyd Popen call that follows, but as a hard failure, not a
    # graceful "unavailable"). Force the same "not available" path these
    # tests actually want to exercise, deterministically, regardless of
    # what's installed on whichever machine runs this suite.
    monkeypatch.setattr(ttyd_manager.manager, "ensure_tab", lambda tab_id, user_id=None, node_target=None: None)
    return TestClient(app)


def test_mismatched_origin_is_rejected(tc):
    with pytest.raises(WebSocketDisconnect) as exc_info:
        with tc.websocket_connect(WS_PATH, headers={"origin": "https://evil.example.com"}):
            pass
    assert exc_info.value.code == 4403


def test_missing_origin_is_rejected(tc):
    with pytest.raises(WebSocketDisconnect) as exc_info:
        with tc.websocket_connect(WS_PATH):
            pass
    assert exc_info.value.code == 4403


def test_matching_origin_is_not_rejected_by_origin_check(tc):
    # A same-origin request gets past _origin_is_trusted - it then fails at
    # the next stage instead (ensure_tab mocked to unavailable, see the `tc`
    # fixture), with a *different* close code (1013, "ttyd unavailable"),
    # proving Origin validation specifically was not what stopped it. The
    # password gate is off by default in this fixture (no
    # CLUSTERDRILL_PASSWORD), so auth.session_is_valid is never even
    # consulted here - see the two tests below for that check specifically.
    with pytest.raises(WebSocketDisconnect) as exc_info:
        with tc.websocket_connect(WS_PATH, headers={"origin": "http://testserver"}):
            pass
    assert exc_info.value.code == 1013


# issue #25's security review: the three tests above only ever exercise
# _origin_is_trusted, since password_gate_enabled() is False by default in
# this test environment (no CLUSTERDRILL_PASSWORD) - auth.session_is_valid
# was never actually proven to reject/admit a connection either way. These
# two turn the gate on directly (monkeypatch, not a real env var + login
# round-trip - keeps this file's scope to reject_unless_authorized's own
# logic, matching every other test here) to close that gap.

def test_gate_enabled_rejects_an_invalid_session(tc, monkeypatch):
    import auth

    monkeypatch.setattr(auth, "password_gate_enabled", lambda: True)
    with pytest.raises(WebSocketDisconnect) as exc_info:
        with tc.websocket_connect(WS_PATH, headers={"origin": "http://testserver"}):
            pass
    assert exc_info.value.code == 4401


def test_gate_enabled_allows_a_valid_session_through(tc, monkeypatch):
    import auth

    monkeypatch.setattr(auth, "password_gate_enabled", lambda: True)
    monkeypatch.setattr(auth, "session_is_valid", lambda session: True)
    # Same "not rejected by this check specifically" pattern as
    # test_matching_origin_is_not_rejected_by_origin_check: a valid session
    # proceeds past reject_unless_authorized entirely, failing at the next
    # stage instead (1013, ttyd unavailable) - a 4401 here would mean the
    # auth check rejected a session it should have admitted.
    with pytest.raises(WebSocketDisconnect) as exc_info:
        with tc.websocket_connect(WS_PATH, headers={"origin": "http://testserver"}):
            pass
    assert exc_info.value.code == 1013
