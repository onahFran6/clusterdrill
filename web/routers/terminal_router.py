"""Terminal reverse proxy (multi-tab) - extracted from
app.py's original monolith (2026-08 restructure) with no behavior change
except the added WebSocket Origin check (see _origin_is_trusted below).

Routes: /terminal/t/{tab_id}/…  (each tab -> its own ttyd port + tmux session)
Legacy: /terminal/…             (tab 1 only)
"""
from __future__ import annotations

import asyncio
import logging

import auth
import httpx
import node_topology
import websockets as websockets_client
import websockets.exceptions as websockets_exceptions
from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from idle import tracker as idle_tracker
from services import question_view
from starlette.requests import Request
from starlette.websockets import WebSocket, WebSocketDisconnect
from ttyd_manager import ensure_session
from ttyd_manager import manager as ttyd_manager

logger = logging.getLogger("clusterdrill.terminal")

router = APIRouter()


def _valid_node_target(raw: str | None) -> str | None:
    """issue #122: a `?node=` query param naming which node a brand-new
    tab should target - "control-plane" (or omitted) for today's existing
    behavior, otherwise a worker node's real name. Checked against a live
    topology query rather than trusted as-is: not a meaningful privilege
    escalation either way (kubectl debug node/<name> only ever runs inside
    this user's own already-restricted kubeconfig, scoped by
    rbac.py's resourceNames-limited Role regardless of which node string
    is given), but there's no reason to hand an arbitrary client-supplied
    string straight to `kubectl debug node/...` when validating it against
    the real node list costs nothing.
    """
    if not raw or raw == "control-plane":
        return None
    topology = node_topology.get_topology()
    if raw in topology.worker_nodes or raw in topology.control_plane_nodes:
        return raw
    return None


def _terminal_instance(tab_id: int, user_id: str | None = None, node_target: str | None = None):
    inst = ttyd_manager.ensure_tab(tab_id, user_id, node_target)
    if inst is None or not inst.is_running:
        raise HTTPException(status_code=503, detail="Terminal is not running.")
    return inst


def _origin_is_trusted(websocket: WebSocket) -> bool:
    """Rejects a WebSocket upgrade whose Origin doesn't match the host it's
    actually connecting to - defense against cross-site WebSocket hijacking
    (CSWSH). SameSite=Lax on the session cookie already blocks a
    cross-origin page's WS handshake from carrying the cookie in most
    modern browsers, but Origin validation is a direct, explicit check
    rather than relying entirely on cookie SameSite semantics holding for
    every client. Self-referential (compares against the WS's own Host
    header) - works unchanged across localhost, an SSH tunnel, or a
    Cloudflare Tunnel's dynamic subdomain, no new config needed.
    """
    origin = websocket.headers.get("origin")
    if origin is None:
        # xterm.js/browsers always send an Origin header for a same-origin
        # WS upgrade - treat a missing one as untrusted rather than
        # silently allowing a non-browser client through.
        return False
    host = websocket.headers.get("host", "")
    try:
        return httpx.URL(origin).netloc.decode("ascii") == host
    except Exception:
        return False


async def reject_unless_authorized(websocket: WebSocket) -> bool:
    """The one call every WebSocket route in this app must make before
    doing anything else - Starlette has no middleware equivalent for
    WebSocket connections (BaseHTTPMiddleware, which covers CSRF/the
    password gate/security headers for every HTTP route, simply does not
    run for the WS protocol), so this is the closest thing to a shared
    enforcement point available. Bundling both checks into one call (rather
    than each WS handler independently calling _origin_is_trusted() and
    auth.session_is_valid() itself, in the right order, with the right
    close codes) means a future handler has one thing to remember instead
    of orchestrating two - tests/test_terminal_ws.py's coverage check
    verifies every registered WebSocket route's handler source actually
    calls this function, so forgetting it entirely is caught by a test, not
    just code review.

    Returns True if the connection was rejected (already closed - caller
    must return immediately), False if the caller should proceed.
    """
    # Cheap header comparison first (fail fast) before the session-cookie
    # check, which does a dict lookup + timestamp comparison. Close code
    # 4403 (CSRF/origin) is distinct from 4401 (auth failure) so
    # client-side debugging can tell the two apart.
    if not _origin_is_trusted(websocket):
        await websocket.close(code=4403)
        return True
    if auth.password_gate_enabled() and not auth.session_is_valid(websocket.session):
        await websocket.close(code=4401)
        return True
    return False


@router.api_route("/terminal/t/{tab_id}/{path:path}", methods=["GET", "POST", "PUT", "OPTIONS"])
async def terminal_proxy_http_tab(request: Request, tab_id: int, path: str):
    user_id = auth.current_user_id(request.session)
    node_target = _valid_node_target(request.query_params.get("node"))
    inst = _terminal_instance(tab_id, user_id, node_target)
    async with httpx.AsyncClient(base_url=inst.base_url, timeout=10.0) as client:
        url = httpx.URL(path=f"/{path}", query=request.url.query.encode("utf-8"))
        body = await request.body()
        upstream = await client.request(
            request.method,
            url,
            headers={
                k: v
                for k, v in request.headers.items()
                if k.lower() not in ("host", "content-length")
            },
            content=body,
        )
        return StreamingResponse(
            upstream.aiter_bytes(),
            status_code=upstream.status_code,
            headers={
                k: v
                for k, v in upstream.headers.items()
                if k.lower() not in ("content-encoding", "content-length", "transfer-encoding", "connection")
            },
        )


@router.websocket("/terminal/t/{tab_id}/{path:path}")
async def terminal_proxy_ws_tab(websocket: WebSocket, tab_id: int, path: str):
    if await reject_unless_authorized(websocket):
        return
    user_id = auth.current_user_id(websocket.session)
    node_target = _valid_node_target(websocket.query_params.get("node"))
    inst = ttyd_manager.ensure_tab(tab_id, user_id, node_target)
    if inst is None or not inst.is_running:
        await websocket.close(code=1013)
        return
    ensure_session(inst, cwd=question_view._current_question_workdir)

    await websocket.accept(subprotocol="tty")
    ws_url = f"ws://{inst.host}:{inst.port}/{path}"
    try:
        async with websockets_client.connect(ws_url, subprotocols=["tty"]) as upstream:
            client_to_upstream = asyncio.create_task(_pump_client_to_upstream(websocket, upstream))
            upstream_to_client = asyncio.create_task(_pump_upstream_to_client(upstream, websocket))
            done, pending = await asyncio.wait(
                [client_to_upstream, upstream_to_client],
                return_when=asyncio.FIRST_COMPLETED,
            )
            for task in pending:
                task.cancel()
    except (OSError, ConnectionRefusedError, websockets_exceptions.WebSocketException):
        logger.warning("terminal proxy tab %s: could not reach ttyd at %s", tab_id, ws_url)
    finally:
        try:
            await websocket.close()
        except RuntimeError:
            pass


@router.api_route("/terminal/{path:path}", methods=["GET", "POST", "PUT", "OPTIONS"])
async def terminal_proxy_http(request: Request, path: str):
    return await terminal_proxy_http_tab(request, 1, path)


@router.websocket("/terminal/{path:path}")
async def terminal_proxy_ws(websocket: WebSocket, path: str):
    await terminal_proxy_ws_tab(websocket, 1, path)


async def _pump_client_to_upstream(websocket: WebSocket, upstream) -> None:
    try:
        while True:
            data = await websocket.receive_bytes()
            # Every inbound frame here is the candidate actually typing (or
            # resizing) inside the terminal - a much more direct "human is
            # here" signal than mouse movement on the surrounding page, and
            # the only way idle.py would ever see activity from someone
            # heads-down in the terminal with the rest of the tab untouched.
            idle_tracker.touch()
            await upstream.send(data)
    except (WebSocketDisconnect, websockets_exceptions.ConnectionClosed):
        pass


async def _pump_upstream_to_client(upstream, websocket: WebSocket) -> None:
    try:
        async for data in upstream:
            if isinstance(data, str):
                await websocket.send_text(data)
            else:
                await websocket.send_bytes(data)
    except (WebSocketDisconnect, websockets_exceptions.ConnectionClosed):
        pass
