"""Discovers the active cluster's real node topology - issue #122 (M7)'s
explicit requirement that the terminal's node-target options come from a
live query, never a hardcoded environment/provider check (Minikube vs.
the AWS lab), so this keeps working correctly without a code change if
the AWS lab's node count changes, or if a future multi-worker Minikube
profile (not built yet) ever exists.

A node is "control-plane" iff kubeadm's own node-role label is present -
CONTROL_PLANE_LABEL_KEYS covers both the current (1.20+) and legacy label
key, matching questions/observability/q107-13-debug-node-shell's own
kubectl get nodes usage. Everything else is a worker. This correctly
yields zero workers on today's single-node Minikube profile (minikube
labels its sole node as control-plane) without needing to know it's
Minikube at all.
"""
from __future__ import annotations

import json
import logging
import subprocess
import time
from dataclasses import dataclass

logger = logging.getLogger("clusterdrill.node_topology")

KUBECTL_TIMEOUT_SECONDS = 10
CONTROL_PLANE_LABEL_KEYS = ("node-role.kubernetes.io/control-plane", "node-role.kubernetes.io/master")

# Node topology changes rarely (a lab isn't autoscaling), but this is
# queried on every question-page render (question.html needs it to show
# the tab-add node choices) - a short cache avoids a kubectl round trip on
# every single page load. Matches this app's existing posture elsewhere
# (bank.refresh() is similarly "cheap, doesn't need to be perfectly live").
_CACHE_TTL_SECONDS = 30.0
_cache: tuple[float, "ClusterTopology"] | None = None


@dataclass(frozen=True)
class ClusterTopology:
    control_plane_nodes: tuple[str, ...]
    worker_nodes: tuple[str, ...]

    @property
    def has_workers(self) -> bool:
        return bool(self.worker_nodes)


_EMPTY = ClusterTopology(control_plane_nodes=(), worker_nodes=())


def _is_control_plane(labels: dict) -> bool:
    return any(key in labels for key in CONTROL_PLANE_LABEL_KEYS)


def _query_topology() -> ClusterTopology:
    try:
        proc = subprocess.run(
            ["kubectl", "get", "nodes", "-o", "json"],
            capture_output=True, text=True, timeout=KUBECTL_TIMEOUT_SECONDS,
        )
    except (subprocess.TimeoutExpired, OSError) as exc:
        logger.warning("node topology query failed: %s", exc)
        return _EMPTY
    if proc.returncode != 0:
        logger.warning("node topology query failed: %s", proc.stderr.strip())
        return _EMPTY
    try:
        items = json.loads(proc.stdout)["items"]
    except (json.JSONDecodeError, KeyError):
        return _EMPTY

    control_plane, workers = [], []
    for item in items:
        name = item.get("metadata", {}).get("name")
        if not name:
            continue
        labels = item.get("metadata", {}).get("labels", {})
        (control_plane if _is_control_plane(labels) else workers).append(name)
    return ClusterTopology(control_plane_nodes=tuple(sorted(control_plane)), worker_nodes=tuple(sorted(workers)))


def get_topology(*, force_refresh: bool = False) -> ClusterTopology:
    """Cached cluster topology - see _CACHE_TTL_SECONDS. Uses the app's own
    (admin) kubectl context, not any per-user restricted one: node listing
    is already granted to every user via rbac.py's shared ClusterRole (the
    same read-only nodes get/list q107-13-debug-node-shell needs), so this
    is not sensitive per-user information - one shared query for
    everyone's page renders is simpler than re-deriving it per user.
    """
    global _cache
    now = time.monotonic()
    if not force_refresh and _cache is not None and now - _cache[0] < _CACHE_TTL_SECONDS:
        return _cache[1]
    topology = _query_topology()
    _cache = (now, topology)
    return topology
