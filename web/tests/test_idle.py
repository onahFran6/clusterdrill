"""idle.IdleTracker: pure dataclass, no I/O - each test builds its own
instance (never touches the module-level `idle.tracker` singleton) so tests
can't pollute each other's idle clocks."""
from __future__ import annotations

import time

from idle import KILL_AFTER_SECONDS, WARN_AFTER_SECONDS, IdleTracker


def test_fresh_tracker_is_not_idle():
    t = IdleTracker()
    assert t.idle_seconds < 1
    assert t.should_kill is False


def test_should_kill_past_threshold():
    t = IdleTracker()
    t.last_activity = time.time() - (KILL_AFTER_SECONDS + 1)
    assert t.should_kill is True


def test_should_not_kill_before_threshold():
    t = IdleTracker()
    t.last_activity = time.time() - (KILL_AFTER_SECONDS - 5)
    assert t.should_kill is False


def test_mark_killed_suppresses_repeat_should_kill():
    t = IdleTracker()
    t.last_activity = time.time() - (KILL_AFTER_SECONDS + 1)
    assert t.should_kill is True
    t.mark_killed()
    assert t.should_kill is False
    assert t.killed_at is not None


def test_touch_resets_clock_and_clears_killed_state():
    t = IdleTracker()
    t.last_activity = time.time() - (KILL_AFTER_SECONDS + 1)
    t.mark_killed()
    assert t.killed_at is not None

    t.touch()
    assert t.killed_at is None
    assert t.idle_seconds < 1
    assert t.should_kill is False


def test_warn_at_and_kill_at_are_relative_to_last_activity():
    t = IdleTracker()
    now = time.time()
    t.last_activity = now
    assert abs(t.warn_at - (now + WARN_AFTER_SECONDS)) < 1
    assert abs(t.kill_at - (now + KILL_AFTER_SECONDS)) < 1


def test_warn_before_kill_ordering():
    # The whole warning-banner UX depends on warn always firing before
    # kill - a configuration mistake here would silently break that.
    assert WARN_AFTER_SECONDS < KILL_AFTER_SECONDS
