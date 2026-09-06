"""Security response headers, including a Content-Security-Policy - added
because this app embeds a real writable shell into a real cluster and may
be reachable from the open internet once a tunnel or reverse proxy is put
in front of it; cheap, standard headers are worth having before any of
that goes further.

Registered as the outermost middleware in app.py (last `add_middleware`
call - see its comment on Starlette's reverse registration order), so these
headers land on every response, including PasswordGateMiddleware's own
redirects to /login and FastAPI's error responses.

CSP is scoped to what this app actually loads, verified against the real
templates rather than a generic lockdown:
    - Mermaid.js from cdn.jsdelivr.net (question.html)
    - Google Fonts from fonts.googleapis.com/fonts.gstatic.com (every page)
    - The terminal iframe (`/terminal/t/{tab_id}/`), same-origin - proxied
      through this app itself (see routers/terminal_router.py), never a
      separate origin, so 'self' covers it for both frame-src (what this
      app embeds) and the WebSocket connection it opens (connect-src).
      connect-src is 'self' alone, not 'self' plus a ws:/wss: scheme-source
      - per the Fetch/CSP spec, 'self' already matches a same-origin
      WebSocket upgrade of this origin (scheme is normalized: ws: for
      http's origin, wss: for https's origin), so adding bare "ws: wss:"
      doesn't extend same-origin coverage at all - it widens the policy to
      allow a WebSocket connection to *any* host on that scheme, which
      directly undercuts the Origin-based CSWSH defense
      (terminal_router._origin_is_trusted) this same hardening pass added:
      if any XSS is ever found elsewhere (e.g. in Markdown rendering),
      injected script could exfiltrate over a WS to an attacker-controlled
      host and CSP wouldn't stop it. Caught in review; fixed here.
    - Inline style="..." attributes are used in a few templates - style-src
      needs 'unsafe-inline' until those are refactored to CSS classes (a
      separate, lower-priority pass). script-src does NOT need
      'unsafe-inline' - the one inline <script> block this app used to have
      (Mermaid's init call in question.html) was moved into static/app.js
      as part of this same hardening pass specifically so script-src could
      stay strict.
"""
from __future__ import annotations

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request

_CSP = "; ".join([
    "default-src 'self'",
    "script-src 'self' https://cdn.jsdelivr.net",
    "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
    "font-src https://fonts.gstatic.com",
    "img-src 'self' data:",
    "connect-src 'self'",
    "frame-src 'self'",
    "frame-ancestors 'self'",
    "base-uri 'none'",
    "form-action 'self'",
    "object-src 'none'",
])

# /terminal/* doesn't render any of this app's own templates - it's
# terminal_router.py proxying ttyd's own HTML/JS verbatim (see that
# module's docstring), and ttyd ships its entire terminal UI as one inline
# <script> block with no nonce/hash this app could add. The strict
# script-src above silently killed it: the proxied page still returned 200
# and the script tag still landed in the DOM, but the browser refused to
# execute it, so the terminal rendered nothing - no console error surfaced
# through the usual channels either, which is what made this hard to catch
# (found by comparing the exact same failure over a direct SSH tunnel,
# ruling out Cloudflare, then noticing this middleware is the outermost one
# and applies unconditionally to every route). Scoped to just this prefix
# rather than loosening the app-wide CSP, since ttyd's bundle is vendored
# software, not user-controlled/templated content subject to XSS injection.
_TERMINAL_CSP = "; ".join([
    "default-src 'self'",
    "script-src 'self' 'unsafe-inline'",
    "style-src 'self' 'unsafe-inline'",
    "connect-src 'self'",
    "img-src 'self' data:",
    "base-uri 'none'",
    "object-src 'none'",
])

_STATIC_HEADERS = {
    "Content-Security-Policy": _CSP,
    "X-Content-Type-Options": "nosniff",
    "Referrer-Policy": "same-origin",
    "Permissions-Policy": "geolocation=(), camera=(), microphone=()",
    # Legacy fallback for browsers that don't honor CSP's frame-ancestors -
    # SAMEORIGIN, not DENY, since question.html frames this app's own
    # /terminal/t/{tab_id}/ route (same-origin, not cross-site).
    "X-Frame-Options": "SAMEORIGIN",
}


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        response = await call_next(request)
        for name, value in _STATIC_HEADERS.items():
            response.headers[name] = value
        if request.url.path.startswith("/terminal/"):
            response.headers["Content-Security-Policy"] = _TERMINAL_CSP
        return response
