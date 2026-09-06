"""The repo's first browser-level E2E fixtures.

Deliberately outside web/tests and clusterdrill/tests - every fixture here
creates and tears down a real, dedicated Minikube profile (~1-2 minutes),
not something the fast/hermetic subprocess-mocked suites should ever pay
for by accident. See this directory's pytest.ini for how to run it.

Never touches the caller's active kubectl context or any profile other
than the appliance's own dedicated `clusterdrill` one - lifecycle actions
go through the real `clusterdrill local ...` CLI entry point (subprocess,
not calling cli.py's functions directly), the same commands an operator
would actually type, so this suite exercises the real learner/operator
path end to end rather than a shortcut around it.
"""
from __future__ import annotations

import platform
import subprocess
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from clusterdrill import cli  # noqa: E402 - needs ROOT on sys.path first

_DOCKER_PLATFORM = {"arm64": "linux/arm64", "aarch64": "linux/arm64"}.get(
    platform.machine().lower(), "linux/amd64"
)

# Not a real secret - only ever set on a disposable, localhost-only,
# throwaway Minikube profile this suite destroys at the end of every run.
E2E_PASSWORD = "e2e-suite-password-not-a-real-secret"  # noqa: S105


def _clusterdrill(*args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, "-m", "clusterdrill.cli", "local", *args],
        cwd=ROOT, text=True, capture_output=True, check=check,
    )


def _build_and_load_appliance_image() -> None:
    """Build the appliance's dev image and load it into the profile's own
    Docker daemon, matching README.md's documented "Local Minikube
    appliance" workflow exactly (same `docker build`/`minikube image load`
    commands an operator runs by hand) - a fresh profile has no image
    cache of its own, so `local install --image clusterdrill:dev` has
    nothing to pull without this step."""
    subprocess.run(
        ["docker", "build", "--platform", _DOCKER_PLATFORM, "--tag", "clusterdrill:dev", str(ROOT)],
        check=True,
    )
    subprocess.run(
        ["minikube", "image", "load", "--profile", cli.PROFILE, "clusterdrill:dev"],
        check=True,
    )


@pytest.fixture(scope="session")
def appliance_profile():
    """Destroy any existing `clusterdrill` profile, start a genuinely
    fresh one with the dev image already loaded into it, and destroy it
    again at the end. `minikube delete` removes every namespace/question
    resource created during the whole session along with the profile
    itself - this is what satisfies "cleans up the profile and
    question resources after every run" without needing separate
    per-question teardown."""
    _clusterdrill("destroy", "--yes", check=False)
    result = _clusterdrill("init")
    assert cli.profile_running(), f"clusterdrill local init did not bring the profile up:\n{result.stdout}\n{result.stderr}"
    _build_and_load_appliance_image()
    try:
        yield
    finally:
        _clusterdrill("destroy", "--yes", check=False)


@pytest.fixture(scope="session")
def appliance_url_password_gated(appliance_profile):
    """Installs with a real password (covers the password-gated flow) and
    keeps a service tunnel open for the whole session.

    Ordering matters and is deliberate: every test using this fixture
    must run (i.e. be defined, in file order - see test_appliance_e2e.py)
    before any test using appliance_url_no_password below, since that
    fixture re-installs this same running profile in --no-password mode.
    Both are session-scoped, so re-running the password-gated tests after
    the no-password ones would find the gate already disabled.
    """
    install = _clusterdrill("install", "--password", E2E_PASSWORD)
    assert install.returncode == 0, install.stderr
    process, url = cli.start_service_url()
    try:
        yield url
    finally:
        if process.poll() is None:
            process.terminate()
            process.wait(timeout=5)


@pytest.fixture(scope="session")
def appliance_url_no_password(appliance_url_password_gated):
    """Re-installs the SAME running profile with --no-password - exercises
    local_install's real "change password mode on an existing install"
    path rather than paying for a second full Minikube profile lifecycle.
    The Service remains ClusterIP across a rollout restart, so the
    already-open loopback tunnel URL from appliance_url_password_gated stays
    valid."""
    install = _clusterdrill("install", "--no-password")
    assert install.returncode == 0, install.stderr
    yield appliance_url_password_gated
