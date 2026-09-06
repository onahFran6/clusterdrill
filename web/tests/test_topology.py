"""topology.storage_profile() unit coverage - subprocess-mocked
(tests/conftest.py's autouse guard forbids a real kubectl call), mirroring
node_count()'s existing fail-closed reasoning but for the None/"unknown"
value instead of zero. node_count() itself has no dedicated unit test in
this suite (only exercised indirectly via test_topology_gating.py's
QuestionBank-level tests) - storage_profile() gets one here since its JSON
parsing/annotation lookup is real new logic this ticket adds, not just a
length count.
"""
from __future__ import annotations

import json
import subprocess

import topology


def _cp(returncode: int = 0, stdout: str = "") -> subprocess.CompletedProcess:
    return subprocess.CompletedProcess(args=[], returncode=returncode, stdout=stdout, stderr="")


def _storageclass_list(items: list[dict]) -> str:
    return json.dumps({"items": items})


def _class(name: str, provisioner: str, is_default: bool) -> dict:
    annotations = {}
    if is_default:
        annotations["storageclass.kubernetes.io/is-default-class"] = "true"
    return {"metadata": {"name": name, "annotations": annotations}, "provisioner": provisioner}


def test_storage_profile_maps_minikube_hostpath(monkeypatch):
    classes = [_class("standard", "k8s.io/minikube-hostpath", is_default=True)]
    monkeypatch.setattr(
        topology.subprocess, "run",
        lambda *a, **kw: _cp(stdout=_storageclass_list(classes)),
    )
    assert topology.storage_profile() == "minikube"


def test_storage_profile_maps_rancher_local_path(monkeypatch):
    classes = [_class("local-path", "rancher.io/local-path", is_default=True)]
    monkeypatch.setattr(
        topology.subprocess, "run",
        lambda *a, **kw: _cp(stdout=_storageclass_list(classes)),
    )
    assert topology.storage_profile() == "local-path"


def test_storage_profile_none_when_no_class_marked_default(monkeypatch):
    classes = [_class("standard", "k8s.io/minikube-hostpath", is_default=False)]
    monkeypatch.setattr(
        topology.subprocess, "run",
        lambda *a, **kw: _cp(stdout=_storageclass_list(classes)),
    )
    assert topology.storage_profile() is None


def test_storage_profile_none_when_default_class_has_unrecognized_provisioner(monkeypatch):
    classes = [_class("custom", "example.com/custom-provisioner", is_default=True)]
    monkeypatch.setattr(
        topology.subprocess, "run",
        lambda *a, **kw: _cp(stdout=_storageclass_list(classes)),
    )
    assert topology.storage_profile() is None


def test_storage_profile_ignores_non_default_classes_when_picking_the_default_one(monkeypatch):
    classes = [
        _class("standard", "k8s.io/minikube-hostpath", is_default=False),
        _class("local-path", "rancher.io/local-path", is_default=True),
    ]
    monkeypatch.setattr(
        topology.subprocess, "run",
        lambda *a, **kw: _cp(stdout=_storageclass_list(classes)),
    )
    assert topology.storage_profile() == "local-path"


def test_storage_profile_fails_closed_on_kubectl_error(monkeypatch):
    def raise_error(*a, **kw):
        raise subprocess.SubprocessError("no reachable cluster")

    monkeypatch.setattr(topology.subprocess, "run", raise_error)
    assert topology.storage_profile() is None


def test_storage_profile_fails_closed_on_malformed_json(monkeypatch):
    monkeypatch.setattr(topology.subprocess, "run", lambda *a, **kw: _cp(stdout="not json"))
    assert topology.storage_profile() is None


def test_storage_profile_fails_closed_when_items_is_not_a_list(monkeypatch):
    monkeypatch.setattr(
        topology.subprocess, "run",
        lambda *a, **kw: _cp(stdout=json.dumps({"items": "unexpected"})),
    )
    assert topology.storage_profile() is None
