"""/healthz and /readyz (R10) - readyz is the readinessProbe target, gated
on readiness.sweep_complete(); healthz backs both probes' liveness side and
must stay instant regardless of sweep state (see health.py's docstring)."""
from __future__ import annotations

import pytest
import readiness


@pytest.fixture(autouse=True)
def _reset_readiness_flag():
    """readiness._sweep_complete is a real, process-wide module global
    (same pattern as sessions.store) - reset around every test so one
    test's mark_sweep_complete() can't leak into the next."""
    readiness._sweep_complete = False
    yield
    readiness._sweep_complete = False


async def test_healthz_is_ok_regardless_of_sweep_state(client):
    response = await client.get("/healthz")
    assert response.status_code == 200
    assert response.json()["ok"] is True


async def test_readyz_503s_before_sweep_completes(client):
    response = await client.get("/readyz")
    assert response.status_code == 503
    assert response.json()["ok"] is False


async def test_readyz_200s_after_sweep_completes(client):
    readiness.mark_sweep_complete()
    response = await client.get("/readyz")
    assert response.status_code == 200
    assert response.json()["ok"] is True
