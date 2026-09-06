"""app._perform_idle_kill - the idle-watchdog's kill action. Verifies (a)
the blocking tmux teardown is offloaded via asyncio.to_thread rather than
run inline on the event loop, and (b) revocation (session_store.clear /
auth.revoke_all_sessions / idle_tracker.mark_killed) happens before that
offloaded call even completes - the actually time-sensitive part shouldn't
wait on the slow part.
"""
from __future__ import annotations

import asyncio
import time
from unittest.mock import MagicMock

import app as app_module
import auth
import pytest
from idle import tracker as idle_tracker
from sessions import store as session_store


@pytest.fixture(autouse=True)
def _reset_shared_singletons():
    # idle.tracker and sessions.store are process-wide singletons (same
    # pattern as auth.py's globals) - reset around every test in this file
    # so mark_killed()/clear() here can't leak into unrelated tests.
    yield
    idle_tracker.touch()
    session_store.clear_all()


async def test_perform_idle_kill_revokes_before_slow_tmux_call_finishes(monkeypatch):
    order: list[str] = []

    def slow_kill_all_tmux_sessions():
        # Simulate the real subprocess round-trip cost without actually
        # touching a subprocess - if revocation were sequenced AFTER this
        # call (the bug being fixed), "revoked" would never appear before
        # "tmux-call-returned" in `order`.
        time.sleep(0.05)
        order.append("tmux-call-returned")

    monkeypatch.setattr(
        app_module.ttyd_manager, "kill_all_tmux_sessions", slow_kill_all_tmux_sessions
    )
    monkeypatch.setattr(
        auth, "revoke_all_sessions", lambda: order.append("revoked") or auth._revoked_before
    )

    idle_tracker.touch()
    await app_module._perform_idle_kill()

    assert order == ["revoked", "tmux-call-returned"]


async def test_perform_idle_kill_offloads_to_a_thread_not_the_event_loop(monkeypatch):
    calls = {"thread_calls": 0}
    real_to_thread = asyncio.to_thread

    async def spying_to_thread(func, *a, **kw):
        calls["thread_calls"] += 1
        return await real_to_thread(func, *a, **kw)

    monkeypatch.setattr(app_module.asyncio, "to_thread", spying_to_thread)
    monkeypatch.setattr(app_module.ttyd_manager, "kill_all_tmux_sessions", lambda: None)

    idle_tracker.touch()
    await app_module._perform_idle_kill()

    assert calls["thread_calls"] == 1


async def test_perform_idle_kill_clears_session_and_marks_killed(monkeypatch):
    monkeypatch.setattr(app_module.ttyd_manager, "kill_all_tmux_sessions", MagicMock())
    session_store.set_active(object(), user_id="alice")  # simulates some user's active session
    idle_tracker.touch()

    await app_module._perform_idle_kill()

    # clear_all(), not just this one user's slot - the idle watchdog is
    # still global; a per-user terminal/idle clock is a known follow-on
    # refinement, not implemented yet (see sessions.py's
    # SessionStore.clear_all docstring).
    assert session_store.get("alice") is None
    assert idle_tracker.killed_at is not None
