# ADR 0004: Give each terminal user their own tmux server

**Status:** Accepted

## Context

Investigating a "text selected in the embedded web terminal can't be
copied" report led to `tmux`'s mouse mode (`set-option -g mouse on` in
`ttyd_manager.py`'s `ensure_session`), which is on deliberately to fix a
real bug (mouse-wheel scroll otherwise gets decoded as up/down-arrow
keypresses, clobbering shell history). A correct copy feature would need to
read the dragged text back out of `tmux` itself, since the mouse is in
`tmux`'s hands once that option is on.

Designing that feature surfaced something more serious: every terminal tab,
for every user, lives on **one shared default tmux server** -
`ttyd_manager.py` never passed `tmux -L <socket>` anywhere. Two concrete
consequences, both verified directly (not just reasoned about):

1. **tmux paste buffers are server-global, not per-session.** Two throwaway
   sessions on a shared server, each writing "the same" named buffer,
   clobbered each other:

   ```sh
   tmux set-buffer -t testA -b "clip_#{session_name}" "hello-from-A"
   tmux set-buffer -t testB -b "clip_#{session_name}" "hello-from-B"
   tmux list-buffers
   # clip_#{session_name}: 12 bytes: "hello-from-B"   <- testA's write is gone
   ```

   (This also disproved the initial idea of using tmux's own
   `#{session_name}` format expansion in a shared keybinding to scope
   buffer names per session - `-b`'s value is not expanded, it's a literal
   string, so both writes landed on the exact same buffer name.) A copy
   feature built on `tmux show-buffer` as-is could hand one candidate a
   buffer holding *another candidate's* just-copied text.
2. **Session names are guessable and unprotected.** Sessions are named
   `clusterdrill-<user_id>-<tab_id>` (`ttyd_manager._tmux_session_name`).
   Since they all live on one server, any candidate's own shell can run
   `tmux attach -t clusterdrill-<other_user_id>-1` right now and land
   inside another candidate's live shell - inheriting whatever RBAC-scoped
   kubeconfig that shell's environment already has (see
   [architecture.md's Multi-user isolation](../architecture.md#multi-user-isolation)
   mechanism 3, which authenticates the *terminal process*, not whoever is
   attached to it). Verified directly: two sessions on one shared server,
   one attached from "inside" the other via `tmux attach`, succeeds with no
   prompt of any kind - this is stock tmux behavior, it has no
   per-session access control at all.

Classroom/multi-user mode is documented as "still experimental, gated
behind its own opt-in" - so this is a real but pre-GA gap, not a production
incident.

## Decision

Give every user their own tmux **server**, not just a distinctly-named
session on a shared one: every `tmux` invocation in `ttyd_manager.py` now
passes `-L clusterdrill-<slot>`, where `<slot>` is the same per-user numeric
slot that already scopes each user's port block (`_user_slot`/`_port_for`).
A new `_tmux_socket_name(user_id)` helper computes it; a
`TtydInstance.tmux_socket_name` property mirrors the existing
`tmux_session_name` one.

Verified the fix directly: with two sessions on two different sockets,
`tmux -L clusterdrill-1 attach -t clusterdrill-bob-1` from inside
`clusterdrill-1`'s own socket fails with `can't find session:
clusterdrill-bob-1` - genuinely invisible, not just differently named.

Two sweep methods (`kill_all_tmux_sessions`, `kill_user_tmux_sessions`)
were simplified as a direct consequence: since a whole user's tabs now
live on one server, a single `kill-server` per known `user_id` replaces the
previous per-tab `kill-session` loop.

Session names and the port-block math are unchanged - only which server
each session lives on changed.

## Consequences

- Closes the cross-user `tmux attach` hijack path outright.
- Unblocked the terminal copy-to-clipboard feature this investigation
  started from: `tmux show-buffer` is now safe to read per-user, since
  buffers are no longer shared across the whole appliance. Built as a
  same-PR follow-up - `ttyd_manager.read_paste_buffer`,
  `terminal_router.py`'s `POST /terminal-clipboard/{tab_id}` and its HTML
  injection of `static/terminal-copy-bridge.js` into ttyd's own page - see
  [architecture.md's Terminal section](../architecture.md#terminal-ttyd_managerpy)
  for how the pieces fit together.
- `docs/architecture.md`'s "Multi-user isolation" section gained a fourth
  mechanism describing this.
- No change to ports, session names, or single-user/no-accounts behavior
  (`user_id=None` still gets slot 0, now expressed as socket
  `clusterdrill-0` instead of the bare default socket).
