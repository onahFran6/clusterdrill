"""The terminal copy-to-clipboard bridge (docs/adr/0004-per-user-tmux-socket.md's
follow-up): terminal_router.py injects static/terminal-copy-bridge.js into
ttyd's own served HTML, and backs it with POST /terminal-clipboard/{tab_id},
which reads back whatever tmux's own mouse-drag-release binding already
copied into this user's tmux paste buffer (ttyd_manager.read_paste_buffer).

Real ttyd is never reached in these tests (conftest.py's subprocess guard
forbids that) - httpx.AsyncClient itself is faked out here so the HTML-
injection logic can be tested against a controlled upstream response,
the same "fake the one real network hop" approach as this file's sibling
route tests use for kubectl/tmux.
"""
from __future__ import annotations

import routers.terminal_router as terminal_router
import ttyd_manager


class _FakeUpstreamResponse:
    def __init__(self, content: bytes, status_code: int = 200, headers: dict | None = None):
        self.content = content
        self.status_code = status_code
        self.headers = headers or {}

    async def aiter_bytes(self):
        yield self.content


class _FakeAsyncClient:
    def __init__(self, response):
        self._response = response

    async def __aenter__(self):
        return self

    async def __aexit__(self, *exc_info):
        return False

    async def request(self, method, url, headers=None, content=None):
        return self._response


def _wire_fake_upstream(monkeypatch, response: _FakeUpstreamResponse):
    monkeypatch.setattr(
        terminal_router.httpx, "AsyncClient",
        lambda **kwargs: _FakeAsyncClient(response),
    )
    monkeypatch.setattr(
        ttyd_manager.manager, "ensure_tab",
        lambda tab_id, user_id=None, node_target=None: ttyd_manager.TtydInstance(
            tab_id=tab_id, user_id=user_id, host="127.0.0.1", port=7681,
        ),
    )
    monkeypatch.setattr(ttyd_manager.TtydInstance, "is_running", property(lambda self: True))


async def test_root_html_gets_the_copy_bridge_script_injected(client, fake_bank, monkeypatch):
    html = b"<html><head></head><body><div>ttyd</div></body></html>"
    _wire_fake_upstream(monkeypatch, _FakeUpstreamResponse(html, headers={"content-type": "text/html; charset=utf-8"}))

    res = await client.get("/terminal/t/1/")

    assert res.status_code == 200
    assert '<script src="/static/terminal-copy-bridge.js"></script></body>' in res.text
    # Exactly once, not duplicated on some other match of the literal string.
    assert res.text.count("terminal-copy-bridge.js") == 1


async def test_non_root_paths_are_streamed_through_unmodified(client, fake_bank, monkeypatch):
    # ttyd's own assets/websocket-upgrade requests under the same tab prefix
    # must never get text-rewritten - only the root document load.
    body = b"<html><body>not the root document</body></html>"
    _wire_fake_upstream(monkeypatch, _FakeUpstreamResponse(body, headers={"content-type": "text/html"}))

    res = await client.get("/terminal/t/1/some-asset.js")

    assert res.content == body
    assert "terminal-copy-bridge.js" not in res.text


async def test_non_html_root_response_is_not_rewritten(client, fake_bank, monkeypatch):
    body = b'{"ok": true}'
    _wire_fake_upstream(monkeypatch, _FakeUpstreamResponse(body, headers={"content-type": "application/json"}))

    res = await client.get("/terminal/t/1/")

    assert res.content == body


async def test_copy_buffer_route_returns_this_users_tmux_buffer(client, fake_bank, monkeypatch):
    # terminal_router.py does `from ttyd_manager import read_paste_buffer`
    # (a from-import, not `import ttyd_manager`) - patch the name in *that*
    # module's namespace, not ttyd_manager's, same gotcha this tests/routes/
    # package's own conftest.py docstring calls out for `bank`.
    monkeypatch.setattr(terminal_router, "read_paste_buffer", lambda user_id: "kubectl get pods -A\n")

    res = await client.post("/terminal-clipboard/1")

    assert res.status_code == 200
    assert res.json() == {"text": "kubectl get pods -A\n"}


async def test_copy_buffer_route_reflects_an_empty_buffer_as_empty_text(client, fake_bank, monkeypatch):
    monkeypatch.setattr(terminal_router, "read_paste_buffer", lambda user_id: "")

    res = await client.post("/terminal-clipboard/1")

    assert res.json() == {"text": ""}
