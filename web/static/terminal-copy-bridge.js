// Injected into ttyd's own served page by terminal_router.py's
// terminal_proxy_http_tab (a text replace before </body> - ttyd's whole UI
// is one embedded, minified asset bundle, there's no template to hook into
// otherwise). Runs same-origin inside the terminal iframe.
//
// tmux's own mouse-drag-release binding already copies a drag selection
// into this user's tmux server's paste buffer for free (ttyd_manager.py's
// ensure_session turns tmux mouse mode on, which is what routes mouse
// events to tmux instead of the browser's native text selection in the
// first place - see docs/adr/0004-per-user-tmux-socket.md for why reading
// that buffer back is now safe to do per-user). This script's only job is
// noticing a real drag happened and bridging that buffer into the actual
// browser clipboard, since nothing does that automatically.
(function () {
  "use strict";

  function currentTabId() {
    const match = window.location.pathname.match(/\/terminal\/t\/(\d+)\//);
    return match ? match[1] : "1";
  }

  function csrfToken() {
    // Same-origin parent page (question.html) carries the token this app's
    // fetch() convention expects (static/app.js's own csrfHeaders()) - this
    // iframe has no meta tag of its own (it's ttyd's page, not ours).
    try {
      const meta = window.parent.document.querySelector('meta[name="csrf-token"]');
      return meta ? meta.content : "";
    } catch {
      return "";
    }
  }

  const tabId = currentTabId();
  const DRAG_THRESHOLD_PX = 4;
  // tmux needs a moment to process the mouse-release SGR sequence and land
  // the selection in its paste buffer before show-buffer would see it.
  const POST_DRAG_DELAY_MS = 120;
  let lastCopiedText = "";
  let dragStart = null;

  function onMouseDown(event) {
    if (event.button !== 0) return;
    dragStart = { x: event.clientX, y: event.clientY };
  }

  function onMouseUp(event) {
    const start = dragStart;
    dragStart = null;
    if (!start) return;
    const movedPx = Math.hypot(event.clientX - start.x, event.clientY - start.y);
    if (movedPx < DRAG_THRESHOLD_PX) return; // a plain click, not a drag-select
    window.setTimeout(fetchAndCopyBuffer, POST_DRAG_DELAY_MS);
  }

  function fetchAndCopyBuffer() {
    fetch("/terminal-clipboard/" + tabId, {
      method: "POST",
      headers: { "X-CSRF-Token": csrfToken() },
    })
      .then((res) => (res.ok ? res.json() : null))
      .then((data) => {
        if (!data || !data.text || data.text === lastCopiedText) return;
        lastCopiedText = data.text;
        if (navigator.clipboard && navigator.clipboard.writeText) {
          return navigator.clipboard.writeText(data.text);
        }
      })
      .catch(() => {
        // Best-effort - a candidate whose browser blocks this is no worse
        // off than before this feature existed.
      });
  }

  // Capture phase so this still sees the events even if xterm.js's own
  // handlers call stopPropagation() during the bubble phase.
  document.addEventListener("mousedown", onMouseDown, true);
  document.addEventListener("mouseup", onMouseUp, true);
})();
