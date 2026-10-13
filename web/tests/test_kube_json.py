"""kube_json.py's plain bool/None functions (kubectl_get_json,
kubectl_apply_json, kubectl_delete) now log kubectl's own stderr on
failure instead of silently discarding it (I05) - these tests pin down
that the logging is bounded and, more importantly, that it's additive:
the return value these three functions' existing callers depend on is
unchanged either way.
"""
from __future__ import annotations

import logging
import subprocess
from unittest.mock import MagicMock

import kube_json
import pytest


@pytest.fixture
def mock_run(monkeypatch):
    mock = MagicMock()
    monkeypatch.setattr(kube_json.subprocess, "run", mock)
    return mock


def test_kubectl_get_json_logs_bounded_stderr_on_nonzero_exit(mock_run, caplog):
    mock_run.return_value = MagicMock(returncode=1, stdout="", stderr="x" * 2000)
    with caplog.at_level(logging.WARNING, logger="clusterdrill.kube_json"):
        result = kube_json.kubectl_get_json("configmap", "foo")
    assert result is None
    assert len(caplog.records) == 1
    assert len(caplog.records[0].message) < 1000  # bounded, not the full 2000-char stderr


def test_kubectl_get_json_returns_none_on_timeout_and_logs(mock_run, caplog):
    mock_run.side_effect = subprocess.TimeoutExpired(cmd="kubectl", timeout=kube_json.KUBECTL_TIMEOUT_SECONDS)
    with caplog.at_level(logging.WARNING, logger="clusterdrill.kube_json"):
        result = kube_json.kubectl_get_json("configmap", "foo")
    assert result is None
    assert len(caplog.records) == 1


def test_kubectl_apply_json_logs_bounded_stderr_and_still_returns_false(mock_run, caplog):
    mock_run.return_value = MagicMock(returncode=1, stdout="", stderr="y" * 2000)
    with caplog.at_level(logging.WARNING, logger="clusterdrill.kube_json"):
        ok = kube_json.kubectl_apply_json({"kind": "ConfigMap", "metadata": {"name": "foo"}})
    assert ok is False
    assert len(caplog.records) == 1
    assert len(caplog.records[0].message) < 1000


def test_kubectl_apply_json_returns_true_on_success_with_no_log(mock_run, caplog):
    mock_run.return_value = MagicMock(returncode=0, stdout="", stderr="")
    with caplog.at_level(logging.WARNING, logger="clusterdrill.kube_json"):
        ok = kube_json.kubectl_apply_json({"kind": "ConfigMap", "metadata": {"name": "foo"}})
    assert ok is True
    assert len(caplog.records) == 0


def test_kubectl_delete_logs_bounded_stderr_and_still_returns_false(mock_run, caplog):
    mock_run.return_value = MagicMock(returncode=1, stdout="", stderr="z" * 2000)
    with caplog.at_level(logging.WARNING, logger="clusterdrill.kube_json"):
        ok = kube_json.kubectl_delete("configmap", "foo")
    assert ok is False
    assert len(caplog.records) == 1
    assert len(caplog.records[0].message) < 1000
