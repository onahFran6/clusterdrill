"""Idle-activity tracking for the terminal/cluster access layer.

Deliberately separate from sessions.py's ActiveSession, which only tracks
*which questions* are currently "in play" for progress bookkeeping - see its
own module docstring. That concept is what question.html's "no practice
session" badge reflects; it has never had anything to do with whether the
embedded terminal still has a live, writable shell into the real cluster.
This module is the thing that actually answers "is a human still here", and
app.py's idle watchdog is what acts on it: killing the tmux sessions
(ttyd_manager.TtydPool.kill_all_tmux_sessions) and revoking the login cookie
(auth.revoke_all_sessions) once nobody's touched the keyboard for
KILL_AFTER_SECONDS.

Single module-level singleton, matching sessions.py's SessionStore and
ttyd_manager.py's TtydPool - this whole app is explicitly single-active-user,
so there is exactly one idle clock to track, not one per visitor.
"""
from __future__ import annotations

import time
from dataclasses import dataclass, field

# 5 minutes of no activity shows a warning; 5 more minutes of continued
# silence (10 total) kills the terminal and logs out. Chosen deliberately
# short given this app is reachable from the open internet behind nothing
# but a single shared password (see auth.py) - a lab left open on a public
# domain is a bigger risk than a slightly-too-eager warning banner.
WARN_AFTER_SECONDS = 5 * 60
KILL_AFTER_SECONDS = 10 * 60


@dataclass
class IdleTracker:
    last_activity: float = field(default_factory=time.time)
    # Set the moment the watchdog actually kills the terminal/session, and
    # cleared again by touch() (i.e. the next successful login - see
    # app.py's login_submit). Lets the watchdog notice "already handled"
    # without re-killing (a no-op but noisy) every poll tick while nobody's
    # logged back in yet.
    killed_at: float | None = None

    def touch(self) -> None:
        self.last_activity = time.time()
        self.killed_at = None

    def mark_killed(self) -> None:
        self.killed_at = time.time()

    @property
    def idle_seconds(self) -> float:
        return time.time() - self.last_activity

    @property
    def warn_at(self) -> float:
        return self.last_activity + WARN_AFTER_SECONDS

    @property
    def kill_at(self) -> float:
        return self.last_activity + KILL_AFTER_SECONDS

    @property
    def should_kill(self) -> bool:
        return self.killed_at is None and self.idle_seconds >= KILL_AFTER_SECONDS


# Module-level singleton - app.py imports this instance directly, same
# pattern as sessions.store and ttyd_manager.manager.
tracker = IdleTracker()
