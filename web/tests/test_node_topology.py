"""node_topology.py: live-cluster node role discovery (issue #122 / M7).
subprocess.run is always mocked - never lets a real `kubectl` binary run,
matching tests/conftest.py's global safety net (which would otherwise
catch an accidental real call outright, not just here).
"""
from __future__ import annotations

import json
from unittest.mock import MagicMock

import node_topology
import pytest


def _nodes_json(*nodes: tuple[str, dict]) -> str:
    return json.dumps({
        "items": [
            {"metadata": {"name": name, "labels": labels}}
            for name, labels in nodes
        ]
    })


@pytest.fixture(autouse=True)
def _clear_cache():
    node_topology._cache = None
    yield
    node_topology._cache = None


def test_single_node_labeled_control_plane_has_no_workers(monkeypatch):
    # Minikube's own default profile - must yield zero workers so the UI
    # never offers a worker option with nothing to connect to.
    stdout = _nodes_json(("clusterdrill", {"node-role.kubernetes.io/control-plane": ""}))
    monkeypatch.setattr(node_topology.subprocess, "run", MagicMock(return_value=MagicMock(returncode=0, stdout=stdout)))

    topology = node_topology.get_topology()

    assert topology.control_plane_nodes == ("clusterdrill",)
    assert topology.worker_nodes == ()
    assert topology.has_workers is False


def test_legacy_master_label_also_counts_as_control_plane(monkeypatch):
    stdout = _nodes_json(("cp-1", {"node-role.kubernetes.io/master": ""}))
    monkeypatch.setattr(node_topology.subprocess, "run", MagicMock(return_value=MagicMock(returncode=0, stdout=stdout)))

    topology = node_topology.get_topology()

    assert topology.control_plane_nodes == ("cp-1",)
    assert topology.worker_nodes == ()


def test_node_with_no_role_label_is_a_worker(monkeypatch):
    # kubeadm's real default: `kubeadm join` never labels a worker node at
    # all - the AWS lab's worker matches this exactly (no `kubectl label`
    # call anywhere in its own bootstrap tooling).
    stdout = _nodes_json(
        ("cp-1", {"node-role.kubernetes.io/control-plane": ""}),
        ("worker-1", {}),
    )
    monkeypatch.setattr(node_topology.subprocess, "run", MagicMock(return_value=MagicMock(returncode=0, stdout=stdout)))

    topology = node_topology.get_topology()

    assert topology.control_plane_nodes == ("cp-1",)
    assert topology.worker_nodes == ("worker-1",)
    assert topology.has_workers is True


def test_multiple_workers_are_all_listed_sorted(monkeypatch):
    stdout = _nodes_json(
        ("cp-1", {"node-role.kubernetes.io/control-plane": ""}),
        ("worker-2", {}),
        ("worker-1", {}),
    )
    monkeypatch.setattr(node_topology.subprocess, "run", MagicMock(return_value=MagicMock(returncode=0, stdout=stdout)))

    topology = node_topology.get_topology()

    assert topology.worker_nodes == ("worker-1", "worker-2")


def test_kubectl_failure_yields_empty_topology_not_an_exception(monkeypatch):
    monkeypatch.setattr(node_topology.subprocess, "run", MagicMock(return_value=MagicMock(returncode=1, stderr="boom")))
    assert node_topology.get_topology() == node_topology._EMPTY


def test_kubectl_timeout_yields_empty_topology(monkeypatch):
    import subprocess as real_subprocess

    def raise_timeout(*a, **kw):
        raise real_subprocess.TimeoutExpired(cmd="kubectl", timeout=10)

    monkeypatch.setattr(node_topology.subprocess, "run", raise_timeout)
    assert node_topology.get_topology() == node_topology._EMPTY


def test_result_is_cached_within_ttl(monkeypatch):
    stdout = _nodes_json(("cp-1", {"node-role.kubernetes.io/control-plane": ""}))
    mock_run = MagicMock(return_value=MagicMock(returncode=0, stdout=stdout))
    monkeypatch.setattr(node_topology.subprocess, "run", mock_run)

    node_topology.get_topology()
    node_topology.get_topology()

    mock_run.assert_called_once()


def test_force_refresh_bypasses_the_cache(monkeypatch):
    stdout = _nodes_json(("cp-1", {"node-role.kubernetes.io/control-plane": ""}))
    mock_run = MagicMock(return_value=MagicMock(returncode=0, stdout=stdout))
    monkeypatch.setattr(node_topology.subprocess, "run", mock_run)

    node_topology.get_topology()
    node_topology.get_topology(force_refresh=True)

    assert mock_run.call_count == 2


def test_cache_expires_after_ttl(monkeypatch):
    stdout = _nodes_json(("cp-1", {"node-role.kubernetes.io/control-plane": ""}))
    mock_run = MagicMock(return_value=MagicMock(returncode=0, stdout=stdout))
    monkeypatch.setattr(node_topology.subprocess, "run", mock_run)

    times = iter([0.0, node_topology._CACHE_TTL_SECONDS + 1])
    monkeypatch.setattr(node_topology.time, "monotonic", lambda: next(times))

    node_topology.get_topology()
    node_topology.get_topology()

    assert mock_run.call_count == 2
