"""Health/readiness check routes - extracted from app.py's original
monolith (2026-08 restructure) with no behavior change beyond readyz, just
a new home."""
from __future__ import annotations

import readiness
from fastapi import APIRouter, Response

from questions import bank

router = APIRouter()


@router.get("/healthz")
def healthz():
    # Deliberately does not call bank.refresh(): a liveness/readiness probe
    # (kubelet hits this every ~10s regardless of real traffic) has no need
    # for guaranteed-fresh bank content, and forcing a full directory
    # walk/YAML re-parse on every single probe was exactly the hot-path cost
    # I01 flagged. question_count/excluded_question_count below reflect
    # whatever real page traffic has last refreshed (or the startup scan, on
    # an idle appliance) - informational, not a liveness signal either way.
    #
    # Deliberately NOT gated on readiness.sweep_complete() (R10): this path
    # also backs the livenessProbe (see deployment manifests), and gating
    # liveness on the sweep would crash-loop the container while cleanup is
    # still running - see /readyz below for the probe that is gated on it.
    return {"ok": True, "question_count": len(bank), "excluded_question_count": bank.excluded_count}


@router.get("/readyz")
def readyz(response: Response):
    # The readinessProbe target (R10), deliberately separate from
    # /healthz above: 503 until this process's startup cluster sweep
    # (app.py's _startup_cluster_sweep) has completed, keeping a freshly
    # started pod out of Service rotation - and thus unable to accept a
    # new session - until any state left by the pod it replaced has
    # actually been swept, not just scheduled as a background task.
    if not readiness.sweep_complete():
        response.status_code = 503
        return {"ok": False, "detail": "startup cluster sweep still in progress"}
    return {"ok": True}
