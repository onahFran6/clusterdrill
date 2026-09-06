"""Shared fixtures for clusterdrill/tests (the local-appliance CLI).

Mirrors practice-bank/web/tests/conftest.py's autouse safety-net pattern:
cli.py's `run()` helper (and a couple of call sites that bypass it, like
`local_install`'s `kubectl apply -f -` and `start_service_url`'s
`minikube service` Popen) all shell out to docker/kubectl/minikube/brew. A
test that forgets to mock `subprocess.run`/`Popen` would otherwise touch
whatever profile the developer running the suite actually has - possibly
the real, disposable-but-real `clusterdrill` Minikube profile, or an
unrelated kubectl context. This fixture turns that failure mode into a
loud, immediate test error instead of a real side effect.
"""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

import pytest

# clusterdrill/tests has no __init__.py (same flat pytest rootdir-insertion
# style as web/tests) - insert practice-bank/ (clusterdrill's own parent)
# onto sys.path so `from clusterdrill import cli` resolves regardless of
# the directory pytest is invoked from.
PRACTICE_BANK_DIR = Path(__file__).resolve().parents[2]
if str(PRACTICE_BANK_DIR) not in sys.path:
    sys.path.insert(0, str(PRACTICE_BANK_DIR))

_FORBIDDEN_BINARIES = {"docker", "kubectl", "minikube", "brew"}


def _binary_name(arg) -> str:
    return str(arg).rsplit("/", 1)[-1]


def _check_argv(args) -> None:
    if not isinstance(args, (list, tuple)) or not args:
        return
    first = _binary_name(args[0])
    if first in _FORBIDDEN_BINARIES:
        raise RuntimeError(
            f"Test attempted a REAL subprocess call to {first!r} "
            f"(argv={list(args)!r}). docker/kubectl/minikube/brew must "
            "always be mocked in these tests - see this fixture's "
            "docstring for why."
        )


@pytest.fixture(autouse=True)
def _forbid_real_docker_kubectl_minikube(monkeypatch):
    """Autouse: applies to every test with no opt-in required. A test that
    wants to assert *how* subprocess.run/Popen would have been called
    should replace clusterdrill.cli.subprocess.run/Popen with its own mock
    inside the test body - that shadows this guard for that test (a
    MagicMock never shells out for real either way), so there's no
    conflict."""
    real_run = subprocess.run

    def guarded_run(args, *a, **kw):
        _check_argv(args)
        return real_run(args, *a, **kw)

    real_popen_init = subprocess.Popen.__init__

    def guarded_popen_init(self, args, *a, **kw):
        _check_argv(args)
        real_popen_init(self, args, *a, **kw)

    monkeypatch.setattr(subprocess, "run", guarded_run)
    monkeypatch.setattr(subprocess.Popen, "__init__", guarded_popen_init)
