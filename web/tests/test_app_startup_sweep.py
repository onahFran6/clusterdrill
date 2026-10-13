"""app._startup_cluster_sweep marks readiness.mark_sweep_complete() once
done (R10) - the signal /readyz gates on. Must fire even when a sweep
call raises, since the function's own per-account try/except already
makes it always run to completion regardless of individual failures."""
from __future__ import annotations

import app as app_module
import pytest
import readiness
import users


@pytest.fixture(autouse=True)
def _reset_readiness_flag():
    readiness._sweep_complete = False
    yield
    readiness._sweep_complete = False


async def test_marks_sweep_complete_after_a_clean_sweep(monkeypatch):
    monkeypatch.setattr(app_module, "run_batch_cleanup", lambda *a, **kw: None)

    assert readiness.sweep_complete() is False
    await app_module._startup_cluster_sweep([])
    assert readiness.sweep_complete() is True


async def test_marks_sweep_complete_even_when_a_sweep_call_raises(monkeypatch):
    def raising_run_batch_cleanup(*a, **kw):
        raise RuntimeError("cluster unreachable")

    monkeypatch.setattr(app_module, "run_batch_cleanup", raising_run_batch_cleanup)
    existing = [users.User(user_id="alice", username="alice", is_admin=False, created_at="2026-01-01T00:00:00Z")]

    await app_module._startup_cluster_sweep(existing)

    assert readiness.sweep_complete() is True
