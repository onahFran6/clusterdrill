"""security_headers.SecurityHeadersMiddleware - response headers present on
every route, and the CSP's exact directive content (a scoped-too-broadly
connect-src shipped once already - see security_headers.py's comment on why
'self' alone is correct - this pins the fix down so it can't quietly widen
again).
"""
from __future__ import annotations

import ttyd_manager


async def test_security_headers_present_on_a_normal_page(client, fake_bank):
    res = await client.get("/topics")
    assert res.headers["x-content-type-options"] == "nosniff"
    assert res.headers["referrer-policy"] == "same-origin"
    assert res.headers["x-frame-options"] == "SAMEORIGIN"
    assert "geolocation=()" in res.headers["permissions-policy"]


async def test_csp_connect_src_is_self_only_not_any_websocket_host(client, fake_bank):
    res = await client.get("/topics")
    csp = res.headers["content-security-policy"]
    directives = {d.strip().split(" ", 1)[0]: d.strip() for d in csp.split(";")}
    assert directives["connect-src"] == "connect-src 'self'"


async def test_csp_frame_ancestors_is_self_not_wildcard(client, fake_bank):
    res = await client.get("/topics")
    csp = res.headers["content-security-policy"]
    assert "frame-ancestors 'self'" in csp


async def test_security_headers_present_on_error_responses_too(client, fake_bank):
    # SecurityHeadersMiddleware is registered outermost specifically so it
    # wraps redirects/errors too (see app.py's middleware-ordering comment)
    # - verify against a real 404, not just a happy-path 200.
    res = await client.get("/topics/does-not-exist")
    assert res.status_code == 404
    assert res.headers["x-content-type-options"] == "nosniff"
    assert "Content-Security-Policy" in res.headers


async def test_normal_page_csp_has_no_unsafe_inline_script(client, fake_bank):
    res = await client.get("/topics")
    csp = res.headers["content-security-policy"]
    directives = {d.strip().split(" ", 1)[0]: d.strip() for d in csp.split(";")}
    assert "'unsafe-inline'" not in directives["script-src"]


async def test_terminal_route_csp_allows_inline_script(client, fake_bank, monkeypatch):
    # ttyd (proxied verbatim by terminal_router.py) ships its whole terminal
    # UI as one inline <script> block with no nonce/hash - the app-wide
    # strict script-src silently killed it (found the hard way: the proxied
    # page still returned 200, but the browser refused to execute the
    # script, so the terminal rendered nothing with no visible error).
    # ensure_tab mocked to unavailable (same as test_terminal_ws.py) so this
    # never spawns a real ttyd - conftest.py's subprocess guard forbids
    # that in tests. The resulting 503 still proves the header is right,
    # same reasoning as the error-response test above: the middleware wraps
    # every response regardless of status.
    monkeypatch.setattr(ttyd_manager.manager, "ensure_tab", lambda tab_id, user_id=None, node_target=None: None)
    res = await client.get("/terminal/t/1/")
    csp = res.headers["content-security-policy"]
    directives = {d.strip().split(" ", 1)[0]: d.strip() for d in csp.split(";")}
    assert "'unsafe-inline'" in directives["script-src"]
