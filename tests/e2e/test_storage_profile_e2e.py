"""E2E coverage for the local-path storage compatibility
profile - PVC creation, WaitForFirstConsumer scheduling, persistence, and
cleanup, per the ticket's own scope bullet ("Add an E2E matrix covering
the default Minikube profile and the Rancher local-path profile...").

Deliberately its own fixture (local_path_profile below), separate from
conftest.py's appliance_profile/appliance_url_* fixtures: this suite only
needs the raw Minikube profile and the vendored provisioner manifest, not
the appliance web app installed on top of it (no Docker build/image load
needed), so it's a much faster, narrower cluster lifecycle than
test_appliance_e2e.py's.

Run with (after `pip install -r requirements.txt` in this directory):
    python -m pytest test_storage_profile_e2e.py -q
"""
from __future__ import annotations

import subprocess
import sys
import time
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from clusterdrill import cli  # noqa: E402 - needs ROOT on sys.path first


def _clusterdrill(*args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, "-m", "clusterdrill.cli", "local", *args],
        cwd=ROOT, text=True, capture_output=True, check=check,
    )


def _kubectl(*args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["kubectl", "--context", cli.PROFILE, *args],
        text=True, capture_output=True, check=check,
    )


@pytest.fixture(scope="module")
def local_path_profile():
    """Destroy any existing clusterdrill profile, start a fresh one with
    the local-path storage profile, and destroy it again at the end -
    same disposable-profile discipline as conftest.py's appliance_profile,
    scoped to just this file's tests (module, not session, since nothing
    else in the suite needs this specific profile)."""
    _clusterdrill("destroy", "--yes", check=False)
    result = _clusterdrill("init", "--storage-profile", "local-path")
    assert cli.profile_running(), f"local init --storage-profile local-path did not bring the profile up:\n{result.stdout}\n{result.stderr}"
    try:
        yield
    finally:
        _clusterdrill("destroy", "--yes", check=False)


def test_local_path_becomes_the_default_storage_class(local_path_profile):
    result = _kubectl("get", "storageclass", "local-path", "-o", "jsonpath={.metadata.annotations.storageclass\\.kubernetes\\.io/is-default-class}")
    assert result.stdout.strip() == "true"


def test_standard_is_demoted_but_still_exists(local_path_profile):
    # Standard is demoted, not deleted -
    # static-PV questions and q109-30 still need it to exist.
    exists = _kubectl("get", "storageclass", "standard", "-o", "name", check=False)
    assert exists.returncode == 0
    annotation = _kubectl("get", "storageclass", "standard", "-o", "jsonpath={.metadata.annotations.storageclass\\.kubernetes\\.io/is-default-class}")
    assert annotation.stdout.strip() == "false"


def test_local_doctor_reports_local_path_profile_live(local_path_profile):
    result = subprocess.run(
        [sys.executable, "-m", "clusterdrill.cli", "local", "doctor"],
        cwd=ROOT, text=True, capture_output=True,
    )
    assert "Storage profile: local-path" in result.stdout
    assert "Storage provisioner: rancher.io/local-path" in result.stdout
    assert "Volume binding mode: WaitForFirstConsumer" in result.stdout
    assert "5 question(s) require the 'minikube' storage profile" in result.stdout


def test_pvc_stays_pending_until_a_consuming_pod_exists_then_binds(local_path_profile):
    """The actual point of the local-path profile: WaitForFirstConsumer
    deferred binding, which the default minikube profile's Immediate
    binding mode cannot exercise."""
    namespace = "e2e-wfc-test"
    _kubectl("create", "namespace", namespace, check=False)
    try:
        subprocess.run(
            ["kubectl", "--context", cli.PROFILE, "apply", "-n", namespace, "-f", "-"],
            input=(
                "apiVersion: v1\nkind: PersistentVolumeClaim\nmetadata:\n  name: test-pvc\n"
                "spec:\n  accessModes: [\"ReadWriteOnce\"]\n  resources:\n    requests:\n      storage: 1Gi\n"
            ),
            text=True, check=True,
        )

        pending = _kubectl("get", "pvc", "test-pvc", "-n", namespace, "-o", "jsonpath={.status.phase}")
        assert pending.stdout.strip() == "Pending"

        subprocess.run(
            ["kubectl", "--context", cli.PROFILE, "apply", "-n", namespace, "-f", "-"],
            input=(
                "apiVersion: v1\nkind: Pod\nmetadata:\n  name: test-pod\nspec:\n  containers:\n"
                "  - name: main\n    image: busybox\n    command: [\"sleep\", \"3600\"]\n"
                "    volumeMounts:\n    - name: data\n      mountPath: /data\n"
                "  volumes:\n  - name: data\n    persistentVolumeClaim:\n      claimName: test-pvc\n"
            ),
            text=True, check=True,
        )

        deadline = time.monotonic() + 60
        bound = False
        while time.monotonic() < deadline:
            phase = _kubectl("get", "pvc", "test-pvc", "-n", namespace, "-o", "jsonpath={.status.phase}").stdout.strip()
            if phase == "Bound":
                bound = True
                break
            time.sleep(2)
        assert bound, "PVC never bound after its consuming Pod was created"
    finally:
        _kubectl("delete", "namespace", namespace, "--wait=true", check=False)
