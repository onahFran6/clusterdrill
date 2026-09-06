"""routers/terminal_router.py's _valid_node_target - issue #122's guard
against handing an arbitrary client-supplied `?node=` string straight to
`kubectl debug node/...`. Pure function, no route/websocket machinery
needed - node_topology.get_topology is mocked directly rather than going
through a real kubectl call.
"""
from __future__ import annotations

import node_topology
import routers.terminal_router as terminal_router


def _topology(control_plane=(), workers=()):
    return node_topology.ClusterTopology(control_plane_nodes=control_plane, worker_nodes=workers)


def test_none_is_control_plane(monkeypatch):
    monkeypatch.setattr(node_topology, "get_topology", lambda **kw: _topology(("cp-1",), ("worker-1",)))
    assert terminal_router._valid_node_target(None) is None


def test_literal_control_plane_string_is_control_plane(monkeypatch):
    monkeypatch.setattr(node_topology, "get_topology", lambda **kw: _topology(("cp-1",), ("worker-1",)))
    assert terminal_router._valid_node_target("control-plane") is None


def test_a_real_worker_name_passes_through(monkeypatch):
    monkeypatch.setattr(node_topology, "get_topology", lambda **kw: _topology(("cp-1",), ("worker-1", "worker-2")))
    assert terminal_router._valid_node_target("worker-2") == "worker-2"


def test_an_unknown_node_name_is_rejected(monkeypatch):
    monkeypatch.setattr(node_topology, "get_topology", lambda **kw: _topology(("cp-1",), ("worker-1",)))
    assert terminal_router._valid_node_target("not-a-real-node") is None


def test_empty_string_is_treated_as_control_plane(monkeypatch):
    monkeypatch.setattr(node_topology, "get_topology", lambda **kw: _topology(("cp-1",), ("worker-1",)))
    assert terminal_router._valid_node_target("") is None
