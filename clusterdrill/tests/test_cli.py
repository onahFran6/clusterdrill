"""clusterdrill/cli.py: the local-appliance CLI's host detection, profile
lifecycle, install, service-URL, and destroy logic. subprocess.run/Popen is
always mocked - see tests/conftest.py's autouse safety-net fixture for why
that is a hard requirement, not a convention, after this repo's real
tmux-session-loss incident (web/tests/conftest.py) with an analogous
unmocked-subprocess failure mode.

Tests are grouped by the cli.py function(s) they cover, in roughly the
order those functions appear in cli.py. `_dispatch()` builds a
subprocess.run side_effect from a small table of "command prefix ->
handler" entries, so each test's mock surface names exactly the real
subprocess calls it expects rather than accepting anything - an unlisted
call raises AssertionError instead of silently returning a MagicMock,
which would otherwise let a wrong-command-line bug pass a test unnoticed.
"""
from __future__ import annotations

import argparse
import json
import subprocess
from typing import Callable
from unittest.mock import MagicMock

import pytest

from clusterdrill import cli


def _cp(returncode: int = 0, stdout: str = "", stderr: str = "") -> subprocess.CompletedProcess:
    return subprocess.CompletedProcess(args=[], returncode=returncode, stdout=stdout, stderr=stderr)


def _profile_list_json(driver: str = "docker", node_count: int = 1, status: str = "Running") -> str:
    return json.dumps({
        "valid": [{
            "Name": cli.PROFILE,
            "Status": status,
            "Config": {"Driver": driver, "Nodes": [{} for _ in range(node_count)]},
        }],
        "invalid": [],
    })


def _storageclass_json(name: str = "standard", provisioner: str = "k8s.io/minikube-hostpath", is_default: bool = True) -> str:
    annotations = {"storageclass.kubernetes.io/is-default-class": "true"} if is_default else {}
    return json.dumps({"items": [{
        "metadata": {"name": name, "annotations": annotations},
        "provisioner": provisioner,
        "reclaimPolicy": "Delete",
    }]})


def _dispatch(handlers: dict[tuple[str, ...], Callable[[list[str]], subprocess.CompletedProcess]]):
    """Build a subprocess.run(cmd, **kwargs) side_effect. `handlers` maps a
    command-prefix tuple (e.g. ("docker", "info")) to a callable that takes
    the full argv and returns a CompletedProcess. The longest matching
    prefix wins, so a test can register a generic ("docker", "info")
    handler and a more specific one only where it needs to (see
    docker_capacity tests, which key off the trailing --format value
    instead since both its calls share the same "docker info" prefix)."""

    def fake_run(cmd, **_kwargs):
        for prefix, handler in handlers.items():
            if tuple(cmd[: len(prefix)]) == prefix:
                return handler(cmd)
        raise AssertionError(f"unexpected subprocess.run call: {cmd!r}")

    return fake_run


def _install_args(**overrides) -> argparse.Namespace:
    defaults = dict(image="clusterdrill:dev", password=None, no_password=False, timeout="5m", installer="manifests")
    defaults.update(overrides)
    return argparse.Namespace(**defaults)


def _init_args(**overrides) -> argparse.Namespace:
    defaults = dict(cpus=None, memory=None, storage_profile=None)
    defaults.update(overrides)
    return argparse.Namespace(**defaults)


# --- run() --------------------------------------------------------------

def test_run_returns_completed_process_on_success(monkeypatch):
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(return_value=_cp(stdout="ok")))
    result = cli.run(["echo", "hi"], capture=True)
    assert result.stdout == "ok"


def test_run_wraps_file_not_found_as_command_error(monkeypatch):
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(side_effect=FileNotFoundError()))
    with pytest.raises(cli.CommandError, match="Required command not found: minikube"):
        cli.run(["minikube", "status"])


def test_run_wraps_called_process_error_using_stderr(monkeypatch):
    error = subprocess.CalledProcessError(1, ["kubectl", "apply"], output="", stderr="boom\n")
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(side_effect=error))
    with pytest.raises(cli.CommandError, match="boom"):
        cli.run(["kubectl", "apply"])


def test_run_wraps_called_process_error_using_stdout_when_no_stderr(monkeypatch):
    error = subprocess.CalledProcessError(1, ["kubectl", "apply"], output="stdout detail\n", stderr="")
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(side_effect=error))
    with pytest.raises(cli.CommandError, match="stdout detail"):
        cli.run(["kubectl", "apply"])


def test_run_wraps_called_process_error_with_generic_message_when_no_output(monkeypatch):
    error = subprocess.CalledProcessError(1, ["kubectl", "apply"], output="", stderr="")
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(side_effect=error))
    with pytest.raises(cli.CommandError, match="Command failed: kubectl apply"):
        cli.run(["kubectl", "apply"])


# --- require_binary() ----------------------------------------------------

def test_require_binary_returns_path_when_found(monkeypatch):
    monkeypatch.setattr(cli.shutil, "which", lambda name: f"/usr/local/bin/{name}")
    assert cli.require_binary("minikube") == "/usr/local/bin/minikube"


def test_require_binary_raises_when_missing(monkeypatch):
    monkeypatch.setattr(cli.shutil, "which", lambda name: None)
    with pytest.raises(cli.CommandError, match="minikube is not installed"):
        cli.require_binary("minikube")


# --- profile_running() ----------------------------------------------------

def test_profile_running_true_when_running(monkeypatch):
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(return_value=_cp(returncode=0, stdout="Running\n")))
    assert cli.profile_running() is True


def test_profile_running_false_on_nonzero_exit(monkeypatch):
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(return_value=_cp(returncode=1, stdout="")))
    assert cli.profile_running() is False


def test_profile_running_false_when_status_not_running(monkeypatch):
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(return_value=_cp(returncode=0, stdout="Stopped\n")))
    assert cli.profile_running() is False


# --- docker_healthy() ------------------------------------------------------

def test_docker_healthy_true_on_zero_exit(monkeypatch):
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(return_value=_cp(returncode=0, stdout="24.0.0")))
    assert cli.docker_healthy() is True


def test_docker_healthy_false_on_nonzero_exit(monkeypatch):
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(return_value=_cp(returncode=1, stdout="")))
    assert cli.docker_healthy() is False


# --- docker_capacity() ------------------------------------------------------
# Host/Docker-capacity detection, including the constrained-memory
# recommendation: usable RAM always keeps 1 GiB back for Docker's own VM
# and Kubernetes system pods, floored at 2 GiB, and never exceeds
# DEFAULT_MEMORY_GIB even when the host has much more.

def _docker_info(ncpu: int, mem_bytes: int):
    def fake_run(cmd, **_kwargs):
        fmt = cmd[-1]
        if fmt == "{{.NCPU}}":
            return _cp(stdout=str(ncpu))
        if fmt == "{{.MemTotal}}":
            return _cp(stdout=str(mem_bytes))
        raise AssertionError(f"unexpected docker info format: {fmt}")
    return fake_run


def test_docker_capacity_caps_at_defaults_on_ample_resources(monkeypatch):
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(side_effect=_docker_info(ncpu=8, mem_bytes=32 * 1024**3)))
    assert cli.docker_capacity() == (4, 8)


def test_docker_capacity_scales_cpus_down_below_default(monkeypatch):
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(side_effect=_docker_info(ncpu=2, mem_bytes=32 * 1024**3)))
    assert cli.docker_capacity() == (2, 8)


def test_docker_capacity_recommends_less_memory_when_constrained(monkeypatch):
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(side_effect=_docker_info(ncpu=4, mem_bytes=3 * 1024**3)))
    assert cli.docker_capacity() == (4, 2)


def test_docker_capacity_never_recommends_below_2gib_floor(monkeypatch):
    # 2 GiB total minus the 1 GiB reserved would compute to 1, but usable
    # memory is floored at 2 GiB regardless.
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(side_effect=_docker_info(ncpu=4, mem_bytes=2 * 1024**3)))
    assert cli.docker_capacity() == (4, 2)


# --- profile_context() / profile_kubectl() ---------------------------------
# Profile-safe command construction: every kubectl call goes through an
# explicit --context flag naming the isolated profile, rather than relying
# on (and mutating) whatever context the user currently has selected.

def test_profile_context_matches_profile_name():
    assert cli.profile_context() == cli.PROFILE


def test_profile_kubectl_raises_when_profile_not_running(monkeypatch):
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(return_value=_cp(returncode=1)))
    with pytest.raises(cli.CommandError, match="is not running"):
        cli.profile_kubectl("get", "nodes")


def test_profile_kubectl_uses_explicit_context_flag(monkeypatch):
    mock_run = MagicMock(side_effect=_dispatch({
        ("minikube", "status"): lambda cmd: _cp(returncode=0, stdout="Running\n"),
        ("kubectl",): lambda cmd: _cp(returncode=0, stdout="get-nodes-output"),
    }))
    monkeypatch.setattr(cli.subprocess, "run", mock_run)

    result = cli.profile_kubectl("get", "nodes", "--no-headers", capture=True)

    assert result.stdout == "get-nodes-output"
    kubectl_calls = [c for c in mock_run.call_args_list if c.args[0][0] == "kubectl"]
    assert len(kubectl_calls) == 1
    assert kubectl_calls[0].args[0] == ["kubectl", "--context", cli.PROFILE, "get", "nodes", "--no-headers"]


# --- local_doctor() ----------------------------------------------------
# question_bank_report() is mocked to a fixed value in every test below
# (except its own dedicated tests further down) so these stay hermetic and
# independent of the real questions/ directory's current content.

def test_local_doctor_flags_unsupported_system(monkeypatch, capsys):
    monkeypatch.setattr(cli.platform, "system", lambda: "Windows")
    monkeypatch.setattr(cli.platform, "machine", lambda: "AMD64")
    monkeypatch.setattr(cli.shutil, "which", lambda name: None)
    monkeypatch.setattr(cli, "question_bank_report", lambda: (0, 0))

    assert cli.local_doctor(argparse.Namespace()) == 1
    out = capsys.readouterr().out
    assert "Only macOS and Ubuntu Linux are supported" in out


def test_local_doctor_flags_missing_binaries(monkeypatch, capsys):
    monkeypatch.setattr(cli.platform, "system", lambda: "Darwin")
    monkeypatch.setattr(cli.platform, "machine", lambda: "arm64")
    monkeypatch.setattr(cli.shutil, "which", lambda name: None)
    monkeypatch.setattr(cli, "question_bank_report", lambda: (0, 0))

    assert cli.local_doctor(argparse.Namespace()) == 1
    out = capsys.readouterr().out
    assert "Install docker" in out
    assert "Install kubectl" in out
    assert "Install minikube" in out


def test_local_doctor_omits_question_bank_line_when_unavailable(monkeypatch, capsys):
    # The real behavior a pip-installed clusterdrill hits - no source
    # checkout, so no web/questions.py to report on. local_doctor must
    # still complete rather than crash, just without that line.
    monkeypatch.setattr(cli.platform, "system", lambda: "Darwin")
    monkeypatch.setattr(cli.platform, "machine", lambda: "arm64")
    monkeypatch.setattr(cli.shutil, "which", lambda name: None)
    monkeypatch.setattr(cli, "question_bank_report", lambda: None)

    assert cli.local_doctor(argparse.Namespace()) == 1
    assert "Question bank:" not in capsys.readouterr().out


def test_local_doctor_flags_unhealthy_docker(monkeypatch, capsys):
    monkeypatch.setattr(cli.platform, "system", lambda: "Darwin")
    monkeypatch.setattr(cli.platform, "machine", lambda: "arm64")
    monkeypatch.setattr(cli.shutil, "which", lambda name: f"/usr/local/bin/{name}")
    monkeypatch.setattr(cli, "question_bank_report", lambda: (0, 0))
    mock_run = MagicMock(side_effect=_dispatch({
        ("docker", "info", "--format", "{{.ServerVersion}}"): lambda cmd: _cp(returncode=1),
        ("minikube", "version"): lambda cmd: _cp(stdout="v1.33.0"),
        ("minikube", "status"): lambda cmd: _cp(returncode=1),
        ("minikube", "profile", "list"): lambda cmd: _cp(returncode=1),
        ("kubectl", "version", "--client"): lambda cmd: _cp(returncode=1),
    }))
    monkeypatch.setattr(cli.subprocess, "run", mock_run)

    assert cli.local_doctor(argparse.Namespace()) == 1
    out = capsys.readouterr().out
    assert "Docker is installed but not healthy" in out


def test_local_doctor_recommends_resources_when_profile_not_running(monkeypatch, capsys):
    monkeypatch.setattr(cli.platform, "system", lambda: "Darwin")
    monkeypatch.setattr(cli.platform, "machine", lambda: "arm64")
    monkeypatch.setattr(cli.shutil, "which", lambda name: f"/usr/local/bin/{name}")
    monkeypatch.setattr(cli, "question_bank_report", lambda: (0, 0))
    mock_run = MagicMock(side_effect=_dispatch({
        ("minikube", "version"): lambda cmd: _cp(stdout="v1.33.0"),
        ("minikube", "status"): lambda cmd: _cp(returncode=1),
        ("minikube", "profile", "list"): lambda cmd: _cp(returncode=1),
        ("kubectl", "version", "--client"): lambda cmd: _cp(returncode=1),
        ("docker", "info", "--format", "{{.ServerVersion}}"): lambda cmd: _cp(returncode=0),
        ("docker", "info"): _docker_info(ncpu=4, mem_bytes=16 * 1024**3),
    }))
    monkeypatch.setattr(cli.subprocess, "run", mock_run)

    assert cli.local_doctor(argparse.Namespace()) == 0
    out = capsys.readouterr().out
    assert "Docker capacity: 4 CPUs, 8 GiB RAM" in out
    assert "Run 'clusterdrill local init' to create the isolated profile." in out


def test_local_doctor_reports_node_count_when_profile_running(monkeypatch, capsys):
    monkeypatch.setattr(cli.platform, "system", lambda: "Darwin")
    monkeypatch.setattr(cli.platform, "machine", lambda: "arm64")
    monkeypatch.setattr(cli.shutil, "which", lambda name: f"/usr/local/bin/{name}")
    monkeypatch.setattr(cli, "question_bank_report", lambda: (0, 0))
    mock_run = MagicMock(side_effect=_dispatch({
        ("minikube", "version"): lambda cmd: _cp(stdout="v1.33.0"),
        ("minikube", "status"): lambda cmd: _cp(returncode=0, stdout="Running\n"),
        ("minikube", "profile", "list"): lambda cmd: _cp(returncode=0, stdout=_profile_list_json(node_count=2)),
        ("docker", "info", "--format", "{{.ServerVersion}}"): lambda cmd: _cp(returncode=0),
        ("docker", "info"): _docker_info(ncpu=4, mem_bytes=16 * 1024**3),
        ("kubectl", "version", "--client"): lambda cmd: _cp(
            returncode=0, stdout=json.dumps({"clientVersion": {"gitVersion": "v1.29.0"}})
        ),
        ("kubectl", "--context", cli.PROFILE, "get", "nodes"): lambda cmd: _cp(returncode=0, stdout="node-a\nnode-b\n"),
        ("kubectl", "--context", cli.PROFILE, "get", "storageclass"): lambda cmd: _cp(returncode=0, stdout=_storageclass_json()),
        ("kubectl", "--context", cli.PROFILE, "version"): lambda cmd: _cp(
            returncode=0, stdout=json.dumps({"serverVersion": {"gitVersion": "v1.29.0"}})
        ),
        ("kubectl", "--context", cli.PROFILE, "auth", "can-i"): lambda cmd: _cp(returncode=0, stdout="yes\n"),
    }))
    monkeypatch.setattr(cli.subprocess, "run", mock_run)

    assert cli.local_doctor(argparse.Namespace()) == 0
    out = capsys.readouterr().out
    assert "Node count: 2" in out
    assert "kubectl client version: v1.29.0" in out
    assert "kubectl server version: v1.29.0" in out
    assert "Profile driver: docker" in out
    assert "Default StorageClass: standard" in out
    assert "Storage provisioner: k8s.io/minikube-hostpath" in out
    assert "Storage profile: minikube" in out
    assert "Volume binding mode: Immediate" in out
    assert "Reclaim policy: Delete" in out
    assert "Volume expansion: not supported" in out
    assert "Local appliance prerequisites are ready." in out


def test_local_doctor_flags_non_docker_driver(monkeypatch, capsys):
    monkeypatch.setattr(cli.platform, "system", lambda: "Darwin")
    monkeypatch.setattr(cli.platform, "machine", lambda: "arm64")
    monkeypatch.setattr(cli.shutil, "which", lambda name: f"/usr/local/bin/{name}")
    monkeypatch.setattr(cli, "question_bank_report", lambda: (0, 0))
    mock_run = MagicMock(side_effect=_dispatch({
        ("minikube", "version"): lambda cmd: _cp(stdout="v1.33.0"),
        ("minikube", "status"): lambda cmd: _cp(returncode=1),
        ("minikube", "profile", "list"): lambda cmd: _cp(
            returncode=0, stdout=_profile_list_json(driver="hyperkit", status="Stopped")
        ),
        ("kubectl", "version", "--client"): lambda cmd: _cp(returncode=1),
        ("docker", "info", "--format", "{{.ServerVersion}}"): lambda cmd: _cp(returncode=0),
        ("docker", "info"): _docker_info(ncpu=4, mem_bytes=16 * 1024**3),
    }))
    monkeypatch.setattr(cli.subprocess, "run", mock_run)

    assert cli.local_doctor(argparse.Namespace()) == 1
    out = capsys.readouterr().out
    assert "Profile driver: hyperkit" in out
    assert "uses the 'hyperkit' driver, not 'docker'" in out


def test_local_doctor_flags_insufficient_configured_nodes(monkeypatch, capsys):
    monkeypatch.setattr(cli.platform, "system", lambda: "Darwin")
    monkeypatch.setattr(cli.platform, "machine", lambda: "arm64")
    monkeypatch.setattr(cli.shutil, "which", lambda name: f"/usr/local/bin/{name}")
    monkeypatch.setattr(cli, "question_bank_report", lambda: (0, 0))
    monkeypatch.setattr(cli, "REQUIRED_NODE_COUNT", 2)
    mock_run = MagicMock(side_effect=_dispatch({
        ("minikube", "version"): lambda cmd: _cp(stdout="v1.33.0"),
        ("minikube", "status"): lambda cmd: _cp(returncode=1),
        ("minikube", "profile", "list"): lambda cmd: _cp(
            returncode=0, stdout=_profile_list_json(node_count=1, status="Stopped")
        ),
        ("kubectl", "version", "--client"): lambda cmd: _cp(returncode=1),
        ("docker", "info", "--format", "{{.ServerVersion}}"): lambda cmd: _cp(returncode=0),
        ("docker", "info"): _docker_info(ncpu=4, mem_bytes=16 * 1024**3),
    }))
    monkeypatch.setattr(cli.subprocess, "run", mock_run)

    assert cli.local_doctor(argparse.Namespace()) == 1
    out = capsys.readouterr().out
    assert "Profile configured node count: 1" in out
    assert "fewer than the required 2" in out


def test_local_doctor_flags_missing_install_permission(monkeypatch, capsys):
    monkeypatch.setattr(cli.platform, "system", lambda: "Darwin")
    monkeypatch.setattr(cli.platform, "machine", lambda: "arm64")
    monkeypatch.setattr(cli.shutil, "which", lambda name: f"/usr/local/bin/{name}")
    monkeypatch.setattr(cli, "question_bank_report", lambda: (0, 0))

    def can_i(cmd):
        verb, resource = cmd[5], cmd[6]
        if verb == "create" and resource == "clusterrolebindings":
            return _cp(returncode=1, stdout="no\n")
        return _cp(returncode=0, stdout="yes\n")

    mock_run = MagicMock(side_effect=_dispatch({
        ("minikube", "version"): lambda cmd: _cp(stdout="v1.33.0"),
        ("minikube", "status"): lambda cmd: _cp(returncode=0, stdout="Running\n"),
        ("minikube", "profile", "list"): lambda cmd: _cp(returncode=0, stdout=_profile_list_json()),
        ("docker", "info", "--format", "{{.ServerVersion}}"): lambda cmd: _cp(returncode=0),
        ("docker", "info"): _docker_info(ncpu=4, mem_bytes=16 * 1024**3),
        ("kubectl", "version", "--client"): lambda cmd: _cp(returncode=1),
        ("kubectl", "--context", cli.PROFILE, "get", "nodes"): lambda cmd: _cp(returncode=0, stdout="node-a\n"),
        ("kubectl", "--context", cli.PROFILE, "get", "storageclass"): lambda cmd: _cp(returncode=0, stdout=_storageclass_json()),
        ("kubectl", "--context", cli.PROFILE, "version"): lambda cmd: _cp(returncode=1),
        ("kubectl", "--context", cli.PROFILE, "auth", "can-i"): can_i,
    }))
    monkeypatch.setattr(cli.subprocess, "run", mock_run)

    assert cli.local_doctor(argparse.Namespace()) == 1
    out = capsys.readouterr().out
    assert "can-i create clusterrolebindings: no" in out
    assert "cannot 'create clusterrolebindings'" in out


def test_local_doctor_flags_no_default_storage_class(monkeypatch, capsys):
    monkeypatch.setattr(cli.platform, "system", lambda: "Darwin")
    monkeypatch.setattr(cli.platform, "machine", lambda: "arm64")
    monkeypatch.setattr(cli.shutil, "which", lambda name: f"/usr/local/bin/{name}")
    monkeypatch.setattr(cli, "question_bank_report", lambda: (0, 0))
    mock_run = MagicMock(side_effect=_dispatch({
        ("minikube", "version"): lambda cmd: _cp(stdout="v1.33.0"),
        ("minikube", "status"): lambda cmd: _cp(returncode=0, stdout="Running\n"),
        ("minikube", "profile", "list"): lambda cmd: _cp(returncode=0, stdout=_profile_list_json()),
        ("docker", "info", "--format", "{{.ServerVersion}}"): lambda cmd: _cp(returncode=0),
        ("docker", "info"): _docker_info(ncpu=4, mem_bytes=16 * 1024**3),
        ("kubectl", "version", "--client"): lambda cmd: _cp(returncode=1),
        ("kubectl", "--context", cli.PROFILE, "get", "nodes"): lambda cmd: _cp(returncode=0, stdout="node-a\n"),
        ("kubectl", "--context", cli.PROFILE, "get", "storageclass"): lambda cmd: _cp(returncode=0, stdout=_storageclass_json(is_default=False)),
        ("kubectl", "--context", cli.PROFILE, "version"): lambda cmd: _cp(returncode=1),
        ("kubectl", "--context", cli.PROFILE, "auth", "can-i"): lambda cmd: _cp(returncode=0, stdout="yes\n"),
    }))
    monkeypatch.setattr(cli.subprocess, "run", mock_run)

    assert cli.local_doctor(argparse.Namespace()) == 1
    out = capsys.readouterr().out
    assert "Default StorageClass: none marked default" in out
    assert "Storage provisioner: unknown" in out
    assert "Storage profile: unknown" in out
    assert "No StorageClass is marked as the cluster default." in out


def test_local_doctor_reports_local_path_profile(monkeypatch, capsys):
    monkeypatch.setattr(cli.platform, "system", lambda: "Darwin")
    monkeypatch.setattr(cli.platform, "machine", lambda: "arm64")
    monkeypatch.setattr(cli.shutil, "which", lambda name: f"/usr/local/bin/{name}")
    monkeypatch.setattr(cli, "question_bank_report", lambda: (0, 0))
    # patch in the WaitForFirstConsumer binding mode the real vendored
    # StorageClass sets - _storageclass_json's default omits it (Immediate).
    parsed = json.loads(_storageclass_json(name="local-path", provisioner="rancher.io/local-path"))
    parsed["items"][0]["volumeBindingMode"] = "WaitForFirstConsumer"
    local_path_class = json.dumps(parsed)
    mock_run = MagicMock(side_effect=_dispatch({
        ("minikube", "version"): lambda cmd: _cp(stdout="v1.33.0"),
        ("minikube", "status"): lambda cmd: _cp(returncode=0, stdout="Running\n"),
        ("minikube", "profile", "list"): lambda cmd: _cp(returncode=0, stdout=_profile_list_json()),
        ("docker", "info", "--format", "{{.ServerVersion}}"): lambda cmd: _cp(returncode=0),
        ("docker", "info"): _docker_info(ncpu=4, mem_bytes=16 * 1024**3),
        ("kubectl", "version", "--client"): lambda cmd: _cp(returncode=1),
        ("kubectl", "--context", cli.PROFILE, "get", "nodes"): lambda cmd: _cp(returncode=0, stdout="node-a\n"),
        ("kubectl", "--context", cli.PROFILE, "get", "storageclass"): lambda cmd: _cp(returncode=0, stdout=local_path_class),
        ("kubectl", "--context", cli.PROFILE, "version"): lambda cmd: _cp(returncode=1),
        ("kubectl", "--context", cli.PROFILE, "auth", "can-i"): lambda cmd: _cp(returncode=0, stdout="yes\n"),
    }))
    monkeypatch.setattr(cli.subprocess, "run", mock_run)

    assert cli.local_doctor(argparse.Namespace()) == 0
    out = capsys.readouterr().out
    assert "Default StorageClass: local-path" in out
    assert "Storage provisioner: rancher.io/local-path" in out
    assert "Storage profile: local-path" in out
    assert "Volume binding mode: WaitForFirstConsumer" in out
    assert "require the 'minikube' storage profile, but this appliance is running 'local-path'" in out
    assert "clusterdrill local init --storage-profile minikube" in out


# --- storage_profile_exclusion_message() -----------------------------------

def test_storage_profile_exclusion_message_none_when_active_profile_unknown():
    assert cli.storage_profile_exclusion_message(None) is None


def test_storage_profile_exclusion_message_none_when_active_profile_satisfies_every_requirement():
    # The real bundled bank's only declared requirement is "minikube"
    # - running under it leaves nothing
    # mismatched.
    assert cli.storage_profile_exclusion_message("minikube") is None


def test_storage_profile_exclusion_message_reports_count_and_remediation_under_mismatch():
    message = cli.storage_profile_exclusion_message("local-path")
    assert message is not None
    assert message.startswith("5 question(s) require the 'minikube' storage profile")
    assert "running 'local-path'" in message
    assert "clusterdrill local destroy && clusterdrill local init --storage-profile minikube" in message


# --- kubectl_client_version() / kubectl_server_version() / minikube_profile_config() ---

def test_kubectl_client_version_parses_git_version(monkeypatch):
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(
        return_value=_cp(returncode=0, stdout=json.dumps({"clientVersion": {"gitVersion": "v1.30.1"}}))
    ))
    assert cli.kubectl_client_version() == "v1.30.1"


def test_kubectl_client_version_returns_none_on_failure(monkeypatch):
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(return_value=_cp(returncode=1)))
    assert cli.kubectl_client_version() is None


def test_kubectl_client_version_returns_none_on_malformed_json(monkeypatch):
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(return_value=_cp(returncode=0, stdout="not json")))
    assert cli.kubectl_client_version() is None


def test_minikube_profile_config_finds_matching_profile(monkeypatch):
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(
        return_value=_cp(returncode=0, stdout=_profile_list_json(driver="docker", node_count=1))
    ))
    config = cli.minikube_profile_config()
    assert config["Driver"] == "docker"
    assert len(config["Nodes"]) == 1


def test_minikube_profile_config_returns_none_when_profile_absent(monkeypatch):
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(
        return_value=_cp(returncode=0, stdout=json.dumps({"valid": [], "invalid": []}))
    ))
    assert cli.minikube_profile_config() is None


def test_minikube_profile_config_returns_none_on_command_failure(monkeypatch):
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(return_value=_cp(returncode=1)))
    assert cli.minikube_profile_config() is None


# --- question_bank_report() ------------------------------------------------
# count_incomplete_question_dirs' own dedicated unit tests against synthetic
# content live in web/tests/test_questions.py, next to discover_questions'
# equivalent tests it mirrors. This test only confirms cli.question_bank_report
# actually wires into that real logic by recomputing the same thing a second, independent way
# and checking they agree - no synthetic fixture needed.

def test_question_bank_report_matches_direct_computation():
    import sys
    if str(cli.WEB_DIR) not in sys.path:
        sys.path.insert(0, str(cli.WEB_DIR))
    from questions import QuestionBank, count_incomplete_question_dirs

    expected_bank = QuestionBank()
    expected_bank.set_node_count(cli.REQUIRED_NODE_COUNT)
    expected = (expected_bank.excluded_count, count_incomplete_question_dirs(expected_bank.questions_dir))

    assert cli.question_bank_report() == expected


def test_question_bank_report_returns_none_when_web_dir_missing(monkeypatch, tmp_path):
    # The real state for a pip-installed clusterdrill, which doesn't bundle
    # question content - see _import_question_bank's docstring.
    monkeypatch.setattr(cli, "WEB_DIR", tmp_path / "no-such-web-dir")
    assert cli.question_bank_report() is None


# --- _import_question_bank() -------------------------------------------

def test_import_question_bank_returns_none_when_web_dir_missing(monkeypatch, tmp_path):
    monkeypatch.setattr(cli, "WEB_DIR", tmp_path / "no-such-web-dir")
    assert cli._import_question_bank() is None


def test_import_question_bank_returns_module_when_web_dir_present():
    assert cli._import_question_bank() is not None


def test_storage_profile_exclusion_message_none_when_web_dir_missing(monkeypatch, tmp_path):
    monkeypatch.setattr(cli, "WEB_DIR", tmp_path / "no-such-web-dir")
    assert cli.storage_profile_exclusion_message("local-path") is None


# --- local_bootstrap() ----------------------------------------------------

def test_local_bootstrap_noop_when_already_installed(monkeypatch, capsys):
    monkeypatch.setattr(cli.shutil, "which", lambda name: "/usr/local/bin/minikube" if name == "minikube" else None)
    assert cli.local_bootstrap(argparse.Namespace(install_prerequisites=False)) == 0
    assert "already installed" in capsys.readouterr().out


def test_local_bootstrap_requires_explicit_acknowledgement(monkeypatch):
    monkeypatch.setattr(cli.shutil, "which", lambda name: None)
    with pytest.raises(cli.CommandError, match="--install-prerequisites"):
        cli.local_bootstrap(argparse.Namespace(install_prerequisites=False))


def test_local_bootstrap_rejects_non_macos(monkeypatch):
    monkeypatch.setattr(cli.shutil, "which", lambda name: None)
    monkeypatch.setattr(cli.platform, "system", lambda: "Linux")
    with pytest.raises(cli.CommandError, match="implemented only for macOS"):
        cli.local_bootstrap(argparse.Namespace(install_prerequisites=True))


def test_local_bootstrap_requires_healthy_docker(monkeypatch):
    monkeypatch.setattr(cli.shutil, "which", lambda name: None)
    monkeypatch.setattr(cli.platform, "system", lambda: "Darwin")
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(return_value=_cp(returncode=1)))
    with pytest.raises(cli.CommandError, match="Docker is unavailable or unhealthy"):
        cli.local_bootstrap(argparse.Namespace(install_prerequisites=True))


def test_local_bootstrap_requires_homebrew(monkeypatch):
    monkeypatch.setattr(cli.shutil, "which", lambda name: None)
    monkeypatch.setattr(cli.platform, "system", lambda: "Darwin")
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(return_value=_cp(returncode=0)))
    with pytest.raises(cli.CommandError, match="Homebrew is required"):
        cli.local_bootstrap(argparse.Namespace(install_prerequisites=True))


def test_local_bootstrap_installs_via_brew_on_macos(monkeypatch, capsys):
    # shutil.which("minikube") must report absent before the brew install
    # and present after it - require_binary("minikube") is called right
    # after `brew install minikube` to verify the install actually worked,
    # so the fake needs to flip state the same way a real PATH lookup
    # would once brew's own subprocess call (below) has "run".
    state = {"minikube_installed": False}

    def fake_which(name):
        if name == "minikube":
            return "/usr/local/bin/minikube" if state["minikube_installed"] else None
        if name == "brew":
            return "/opt/homebrew/bin/brew"
        return f"/usr/local/bin/{name}"

    monkeypatch.setattr(cli.shutil, "which", fake_which)
    monkeypatch.setattr(cli.platform, "system", lambda: "Darwin")

    def _brew_install(cmd):
        state["minikube_installed"] = True
        return _cp(returncode=0)

    mock_run = MagicMock(side_effect=_dispatch({
        ("docker", "info"): lambda cmd: _cp(returncode=0),
        ("brew", "install", "minikube"): _brew_install,
        ("minikube", "version"): lambda cmd: _cp(returncode=0, stdout="v1.33.0"),
    }))
    monkeypatch.setattr(cli.subprocess, "run", mock_run)

    assert cli.local_bootstrap(argparse.Namespace(install_prerequisites=True)) == 0
    assert "Minikube installed and verified." in capsys.readouterr().out
    brew_calls = [c for c in mock_run.call_args_list if c.args[0][0] == "brew"]
    assert brew_calls[0].args[0] == ["brew", "install", "minikube"]


# --- default_storage_class() / apply_local_path_provisioner() -------------
# Reading and (only for the local-path profile) mutating the
# cluster's default StorageClass.

def test_default_storage_class_returns_the_item_marked_default(monkeypatch):
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(
        return_value=_cp(returncode=0, stdout=_storageclass_json(name="local-path", provisioner="rancher.io/local-path"))
    ))
    result = cli.default_storage_class()
    assert result["metadata"]["name"] == "local-path"
    assert result["provisioner"] == "rancher.io/local-path"


def test_default_storage_class_returns_none_when_none_marked_default(monkeypatch):
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(
        return_value=_cp(returncode=0, stdout=_storageclass_json(is_default=False))
    ))
    assert cli.default_storage_class() is None


def test_default_storage_class_returns_none_on_command_failure(monkeypatch):
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(return_value=_cp(returncode=1)))
    assert cli.default_storage_class() is None


def test_default_storage_class_returns_none_on_malformed_json(monkeypatch):
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(return_value=_cp(returncode=0, stdout="not json")))
    assert cli.default_storage_class() is None


def test_apply_local_path_provisioner_raises_if_manifest_missing(tmp_path, monkeypatch):
    monkeypatch.setattr(cli, "LOCAL_PATH_MANIFEST", tmp_path / "does-not-exist.yaml")
    with pytest.raises(cli.CommandError, match="local-path manifest is missing"):
        cli.apply_local_path_provisioner()


def test_apply_local_path_provisioner_applies_waits_and_demotes_previous_default(tmp_path, monkeypatch):
    manifest_path = tmp_path / "local-path-provisioner.yaml"
    manifest_path.write_text("kind: Namespace\nmetadata:\n  name: local-path-storage\n")
    monkeypatch.setattr(cli, "LOCAL_PATH_MANIFEST", manifest_path)

    apply_calls: list[list[str]] = []
    monkeypatch.setattr(
        cli.subprocess, "run",
        lambda cmd, **kwargs: apply_calls.append(cmd) or _cp(returncode=0),
    )
    monkeypatch.setattr(cli, "default_storage_class", lambda: {"metadata": {"name": "standard"}})

    profile_kubectl_calls: list[tuple] = []
    monkeypatch.setattr(
        cli, "profile_kubectl",
        lambda *args, **kwargs: profile_kubectl_calls.append(args) or _cp(returncode=0),
    )

    cli.apply_local_path_provisioner()

    assert apply_calls == [["kubectl", "--context", cli.PROFILE, "apply", "-f", "-"]]
    assert profile_kubectl_calls == [
        ("rollout", "status", "deployment/local-path-provisioner", "--namespace", cli.LOCAL_PATH_NAMESPACE, "--timeout", "3m"),
        ("patch", "storageclass", "standard", "--type", "merge", "-p", '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'),
        ("patch", "storageclass", "local-path", "--type", "merge", "-p", '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'),
    ]


def test_apply_local_path_provisioner_skips_demoting_when_already_default(tmp_path, monkeypatch):
    # Re-running `local init --storage-profile local-path` (e.g. after a
    # crash) shouldn't try to patch local-path's own annotation to false
    # then true again via a spurious "demote the previous default" step.
    manifest_path = tmp_path / "local-path-provisioner.yaml"
    manifest_path.write_text("kind: Namespace\nmetadata:\n  name: local-path-storage\n")
    monkeypatch.setattr(cli, "LOCAL_PATH_MANIFEST", manifest_path)
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(return_value=_cp(returncode=0)))
    monkeypatch.setattr(cli, "default_storage_class", lambda: {"metadata": {"name": "local-path"}})

    profile_kubectl_calls: list[tuple] = []
    monkeypatch.setattr(
        cli, "profile_kubectl",
        lambda *args, **kwargs: profile_kubectl_calls.append(args) or _cp(returncode=0),
    )

    cli.apply_local_path_provisioner()

    assert profile_kubectl_calls == [
        ("rollout", "status", "deployment/local-path-provisioner", "--namespace", cli.LOCAL_PATH_NAMESPACE, "--timeout", "3m"),
        ("patch", "storageclass", "local-path", "--type", "merge", "-p", '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'),
    ]


def test_apply_local_path_provisioner_raises_on_apply_failure(tmp_path, monkeypatch):
    manifest_path = tmp_path / "local-path-provisioner.yaml"
    manifest_path.write_text("kind: Namespace\n")
    monkeypatch.setattr(cli, "LOCAL_PATH_MANIFEST", manifest_path)
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(return_value=_cp(returncode=1)))
    monkeypatch.setattr(cli, "default_storage_class", lambda: None)

    with pytest.raises(cli.CommandError, match="Could not apply the local-path-provisioner manifest"):
        cli.apply_local_path_provisioner()


# --- local_init() ----------------------------------------------------
# Profile-safe command construction (explicit --profile/--driver/--cpus/
# --memory flags) and restoration of the prior kubectl context.

def _docker_info_and_health(ncpu: int = 4, mem_bytes: int = 16 * 1024**3):
    """A single handler for every `docker info --format ...` call
    local_init makes: docker_healthy()'s health probe plus
    docker_capacity()'s NCPU/MemTotal reads, which local_init calls
    unconditionally even when both --cpus and --memory are explicitly
    overridden (its recommendation is simply unused in that case)."""
    def handler(cmd):
        fmt = cmd[-1]
        if fmt == "{{.ServerVersion}}":
            return _cp(returncode=0, stdout="24.0.0")
        if fmt == "{{.NCPU}}":
            return _cp(stdout=str(ncpu))
        if fmt == "{{.MemTotal}}":
            return _cp(stdout=str(mem_bytes))
        raise AssertionError(f"unexpected docker info format: {fmt}")
    return handler


def _init_dispatch(*, previous_context: str, profile_running_after_start: bool = True):
    return _dispatch({
        ("docker", "info"): _docker_info_and_health(),
        ("kubectl", "config", "current-context"): lambda cmd: _cp(returncode=0, stdout=f"{previous_context}\n"),
        ("minikube", "start"): lambda cmd: _cp(returncode=0),
        ("minikube", "status"): lambda cmd: _cp(returncode=0, stdout="Running\n") if profile_running_after_start else _cp(returncode=1),
        ("kubectl", "config", "use-context"): lambda cmd: _cp(returncode=0),
    })


def test_local_init_requires_healthy_docker(monkeypatch):
    monkeypatch.setattr(cli.shutil, "which", lambda name: f"/usr/local/bin/{name}")
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(return_value=_cp(returncode=1)))
    with pytest.raises(cli.CommandError, match="Docker is unavailable or unhealthy"):
        cli.local_init(_init_args())


def test_local_init_uses_docker_capacity_recommendation_by_default(monkeypatch):
    monkeypatch.setattr(cli.shutil, "which", lambda name: f"/usr/local/bin/{name}")
    mock_run = MagicMock(side_effect=_dispatch({
        ("docker", "info", "--format", "{{.ServerVersion}}"): lambda cmd: _cp(returncode=0),
        ("docker", "info"): _docker_info(ncpu=8, mem_bytes=32 * 1024**3),
        ("kubectl", "config", "current-context"): lambda cmd: _cp(returncode=0, stdout="original\n"),
        ("minikube", "start"): lambda cmd: _cp(returncode=0),
        ("minikube", "status"): lambda cmd: _cp(returncode=0, stdout="Running\n"),
        ("kubectl", "config", "use-context"): lambda cmd: _cp(returncode=0),
    }))
    monkeypatch.setattr(cli.subprocess, "run", mock_run)

    assert cli.local_init(_init_args()) == 0
    start_calls = [c for c in mock_run.call_args_list if c.args[0][:2] == ["minikube", "start"]]
    assert start_calls[0].args[0] == [
        "minikube", "start", "--profile", cli.PROFILE, "--driver", "docker", "--cpus=4", "--memory=8g",
    ]


def test_local_init_honors_explicit_cpu_and_memory_overrides(monkeypatch):
    monkeypatch.setattr(cli.shutil, "which", lambda name: f"/usr/local/bin/{name}")
    mock_run = MagicMock(side_effect=_init_dispatch(previous_context=cli.PROFILE))
    monkeypatch.setattr(cli.subprocess, "run", mock_run)

    assert cli.local_init(_init_args(cpus=2, memory="3g")) == 0
    start_calls = [c for c in mock_run.call_args_list if c.args[0][:2] == ["minikube", "start"]]
    assert start_calls[0].args[0] == [
        "minikube", "start", "--profile", cli.PROFILE, "--driver", "docker", "--cpus=2", "--memory=3g",
    ]


def test_local_init_raises_if_minikube_reports_success_but_not_running(monkeypatch):
    monkeypatch.setattr(cli.shutil, "which", lambda name: f"/usr/local/bin/{name}")
    monkeypatch.setattr(
        cli.subprocess, "run",
        MagicMock(side_effect=_init_dispatch(previous_context="original", profile_running_after_start=False)),
    )
    with pytest.raises(cli.CommandError, match="is not running"):
        cli.local_init(_init_args(cpus=2, memory="3g"))


def test_local_init_restores_previous_kubectl_context(monkeypatch):
    monkeypatch.setattr(cli.shutil, "which", lambda name: f"/usr/local/bin/{name}")
    mock_run = MagicMock(side_effect=_init_dispatch(previous_context="original-context"))
    monkeypatch.setattr(cli.subprocess, "run", mock_run)

    assert cli.local_init(_init_args(cpus=2, memory="3g")) == 0
    restore_calls = [c for c in mock_run.call_args_list if c.args[0][:3] == ["kubectl", "config", "use-context"]]
    assert len(restore_calls) == 1
    assert restore_calls[0].args[0] == ["kubectl", "config", "use-context", "original-context"]


def test_local_init_skips_restore_when_context_already_profile(monkeypatch):
    monkeypatch.setattr(cli.shutil, "which", lambda name: f"/usr/local/bin/{name}")
    mock_run = MagicMock(side_effect=_init_dispatch(previous_context=cli.PROFILE))
    monkeypatch.setattr(cli.subprocess, "run", mock_run)

    assert cli.local_init(_init_args(cpus=2, memory="3g")) == 0
    restore_calls = [c for c in mock_run.call_args_list if c.args[0][:3] == ["kubectl", "config", "use-context"]]
    assert restore_calls == []


def test_local_init_skips_restore_when_no_previous_context(monkeypatch):
    monkeypatch.setattr(cli.shutil, "which", lambda name: f"/usr/local/bin/{name}")
    mock_run = MagicMock(side_effect=_init_dispatch(previous_context=""))
    monkeypatch.setattr(cli.subprocess, "run", mock_run)

    assert cli.local_init(_init_args(cpus=2, memory="3g")) == 0
    restore_calls = [c for c in mock_run.call_args_list if c.args[0][:3] == ["kubectl", "config", "use-context"]]
    assert restore_calls == []


def test_local_init_default_storage_profile_never_applies_local_path(monkeypatch):
    monkeypatch.setattr(cli.shutil, "which", lambda name: f"/usr/local/bin/{name}")
    mock_run = MagicMock(side_effect=_init_dispatch(previous_context=cli.PROFILE))
    monkeypatch.setattr(cli.subprocess, "run", mock_run)
    apply_mock = MagicMock()
    monkeypatch.setattr(cli, "apply_local_path_provisioner", apply_mock)

    assert cli.local_init(_init_args()) == 0
    apply_mock.assert_not_called()


def test_local_init_storage_profile_local_path_applies_the_provisioner(monkeypatch, capsys):
    monkeypatch.setattr(cli.shutil, "which", lambda name: f"/usr/local/bin/{name}")
    mock_run = MagicMock(side_effect=_init_dispatch(previous_context=cli.PROFILE))
    monkeypatch.setattr(cli.subprocess, "run", mock_run)
    apply_mock = MagicMock()
    monkeypatch.setattr(cli, "apply_local_path_provisioner", apply_mock)

    assert cli.local_init(_init_args(storage_profile="local-path")) == 0
    apply_mock.assert_called_once_with()
    assert "storage profile 'local-path'" in capsys.readouterr().out


# --- render_manifest() ----------------------------------------------------

def test_render_manifest_substitutes_image_and_password(tmp_path, monkeypatch):
    manifest_path = tmp_path / "local-appliance.yaml"
    manifest_path.write_text("image: ${CLUSTERDRILL_IMAGE}\npassword: \"${CLUSTERDRILL_PASSWORD}\"\n")
    monkeypatch.setattr(cli, "MANIFEST", manifest_path)

    rendered = cli.render_manifest("clusterdrill:dev", "s3cr3t")

    assert "image: clusterdrill:dev" in rendered
    assert 'password: "s3cr3t"' in rendered
    assert "${CLUSTERDRILL_IMAGE}" not in rendered
    assert "${CLUSTERDRILL_PASSWORD}" not in rendered


def test_render_manifest_substitutes_explicit_version(tmp_path, monkeypatch):
    manifest_path = tmp_path / "local-appliance.yaml"
    manifest_path.write_text('version: "${CLUSTERDRILL_VERSION}"\n')
    monkeypatch.setattr(cli, "MANIFEST", manifest_path)

    rendered = cli.render_manifest("clusterdrill:dev", "s3cr3t", version="9.9.9")

    assert 'version: "9.9.9"' in rendered


def test_render_manifest_defaults_version_to_installed_package(tmp_path, monkeypatch):
    manifest_path = tmp_path / "local-appliance.yaml"
    manifest_path.write_text('version: "${CLUSTERDRILL_VERSION}"\n')
    monkeypatch.setattr(cli, "MANIFEST", manifest_path)
    monkeypatch.setattr(cli, "installed_version", lambda: "0.1.0")

    rendered = cli.render_manifest("clusterdrill:dev", "s3cr3t")

    assert 'version: "0.1.0"' in rendered


def test_render_manifest_falls_back_to_dev_version_when_unresolvable(tmp_path, monkeypatch):
    manifest_path = tmp_path / "local-appliance.yaml"
    manifest_path.write_text('version: "${CLUSTERDRILL_VERSION}"\n')
    monkeypatch.setattr(cli, "MANIFEST", manifest_path)
    monkeypatch.setattr(cli, "installed_version", lambda: None)

    rendered = cli.render_manifest("clusterdrill:dev", "s3cr3t")

    assert 'version: "dev"' in rendered


def test_render_manifest_raises_when_manifest_missing(tmp_path, monkeypatch):
    monkeypatch.setattr(cli, "MANIFEST", tmp_path / "does-not-exist.yaml")
    with pytest.raises(cli.CommandError, match="Packaged manifest is missing"):
        cli.render_manifest("clusterdrill:dev", "s3cr3t")


# --- installed_password() ----------------------------------------------

def test_installed_password_returns_none_when_secret_missing(monkeypatch):
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(return_value=_cp(returncode=1)))
    assert cli.installed_password() is None


def test_installed_password_returns_none_on_empty_stdout(monkeypatch):
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(return_value=_cp(returncode=0, stdout="")))
    assert cli.installed_password() is None


def test_installed_password_decodes_base64_value(monkeypatch):
    import base64
    encoded = base64.b64encode(b"hunter2").decode()
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(return_value=_cp(returncode=0, stdout=f"{encoded}\n")))
    assert cli.installed_password() == "hunter2"


# --- _has_existing_accounts() -------------------------------------------

def test_has_existing_accounts_false_when_no_secrets_found(monkeypatch):
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(return_value=_cp(returncode=0, stdout="")))
    assert cli._has_existing_accounts() is False


def test_has_existing_accounts_false_on_nonzero_returncode(monkeypatch):
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(return_value=_cp(returncode=1)))
    assert cli._has_existing_accounts() is False


def test_has_existing_accounts_true_when_a_user_secret_exists(monkeypatch):
    monkeypatch.setattr(
        cli.subprocess, "run",
        MagicMock(return_value=_cp(returncode=0, stdout="secret/clusterdrill-user-admin\n")),
    )
    assert cli._has_existing_accounts() is True


def test_remove_shared_cluster_user_rbac_removes_only_clusterdrill_identities(monkeypatch):
    calls = []

    def fake_profile_kubectl(*args, capture=False):
        calls.append((args, capture))
        if args[:3] == ("get", "clusterrolebindings", "-o"):
            return _cp(stdout=json.dumps({"items": [
                {"metadata": {"name": "ckad-practice-cluster-scoped-access-alice"}},
                {"metadata": {"name": "unrelated-binding"}},
            ]}))
        return _cp()

    monkeypatch.setattr(cli, "profile_kubectl", fake_profile_kubectl)

    cli.remove_shared_cluster_user_rbac()

    assert (("delete", "namespace", "ckad-practice-system", "--ignore-not-found", "--wait=true"), False) in calls
    assert (("delete", "clusterrolebinding", "ckad-practice-cluster-scoped-access-alice", "--ignore-not-found"), False) in calls
    assert (("delete", "clusterrole", "ckad-practice-cluster-scoped-access", "--ignore-not-found"), False) in calls
    assert not any("unrelated-binding" in args for args, _ in calls)


# --- local_install() ----------------------------------------------------
# Password / no-password / existing-password installation behavior, plus
# development-image and immutable-image validation.

def _install_dispatch(*, existing_password_b64: str = "", apply_returncode: int = 0, has_existing_accounts: bool = False):
    return _dispatch({
        ("minikube", "status"): lambda cmd: _cp(returncode=0, stdout="Running\n"),
        # More specific than the generic "get secret" prefix below - the
        # accounts-existence check (_has_existing_accounts) - so it's
        # registered first (see _dispatch's "longest prefix wins" docstring).
        ("kubectl", "--context", cli.PROFILE, "get", "secret", "-n", cli.NAMESPACE, "-l", cli.USER_ACCOUNT_LABEL_SELECTOR): lambda cmd: (
            _cp(returncode=0, stdout="secret/clusterdrill-user-admin\n") if has_existing_accounts else _cp(returncode=0, stdout="")
        ),
        ("kubectl", "--context", cli.PROFILE, "get", "secret"): lambda cmd: (
            _cp(returncode=0, stdout=f"{existing_password_b64}\n") if existing_password_b64 else _cp(returncode=1)
        ),
        ("kubectl", "--context", cli.PROFILE, "apply"): lambda cmd: _cp(returncode=apply_returncode),
        ("kubectl", "--context", cli.PROFILE, "rollout"): lambda cmd: _cp(returncode=0),
    })


def _patch_install(monkeypatch, tmp_path, *, existing_password_b64: str = "", apply_returncode: int = 0, has_existing_accounts: bool = False):
    manifest_path = tmp_path / "local-appliance.yaml"
    manifest_path.write_text("image: ${CLUSTERDRILL_IMAGE}\npassword: \"${CLUSTERDRILL_PASSWORD}\"\n")
    monkeypatch.setattr(cli, "MANIFEST", manifest_path)
    monkeypatch.setattr(cli.shutil, "which", lambda name: f"/usr/local/bin/{name}")
    mock_run = MagicMock(side_effect=_install_dispatch(
        existing_password_b64=existing_password_b64, apply_returncode=apply_returncode,
        has_existing_accounts=has_existing_accounts,
    ))
    monkeypatch.setattr(cli.subprocess, "run", mock_run)
    monkeypatch.setattr(cli, "remove_shared_cluster_user_rbac", lambda: None)
    return mock_run


def test_local_install_rejects_mutable_image(monkeypatch, tmp_path):
    # Neither pinned by digest nor under the local clusterdrill: dev-image
    # namespace - the mutable-release-image guard must reject it, even
    # though "latest" is a syntactically valid tag.
    _patch_install(monkeypatch, tmp_path)
    with pytest.raises(cli.CommandError, match="Refusing a mutable release image"):
        cli.local_install(_install_args(image="ghcr.io/example/clusterdrill:latest"))


def test_local_install_accepts_sha256_pinned_image(monkeypatch, tmp_path, capsys):
    _patch_install(monkeypatch, tmp_path)
    args = _install_args(image="ghcr.io/example/clusterdrill@sha256:" + "a" * 64)
    assert cli.local_install(args) == 0
    assert "Installed" in capsys.readouterr().out


def test_local_install_accepts_dev_tag_image(monkeypatch, tmp_path, capsys):
    _patch_install(monkeypatch, tmp_path)
    assert cli.local_install(_install_args(image="clusterdrill:dev")) == 0


def test_local_install_requires_running_profile(monkeypatch, tmp_path):
    monkeypatch.setattr(cli.shutil, "which", lambda name: f"/usr/local/bin/{name}")
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(return_value=_cp(returncode=1)))
    with pytest.raises(cli.CommandError, match="is not running"):
        cli.local_install(_install_args())


def test_local_install_generates_password_when_none_exists(monkeypatch, tmp_path, capsys):
    _patch_install(monkeypatch, tmp_path)
    monkeypatch.setattr(cli.secrets, "token_urlsafe", lambda n: "generated-secret")

    assert cli.local_install(_install_args()) == 0

    out = capsys.readouterr().out
    assert "Local login password: generated-secret" in out


def test_local_install_reuses_existing_password_when_not_specified(monkeypatch, tmp_path, capsys):
    import base64
    existing_b64 = base64.b64encode(b"already-set").decode()
    _patch_install(monkeypatch, tmp_path, existing_password_b64=existing_b64)

    assert cli.local_install(_install_args()) == 0

    out = capsys.readouterr().out
    assert "Local login password: already-set" in out


def test_local_install_rejects_password_change_conflict(monkeypatch, tmp_path):
    import base64
    existing_b64 = base64.b64encode(b"already-set").decode()
    _patch_install(monkeypatch, tmp_path, existing_password_b64=existing_b64)

    with pytest.raises(cli.CommandError, match="Refusing to change it"):
        cli.local_install(_install_args(password="different-password"))


def test_local_install_allows_matching_password_reinstall(monkeypatch, tmp_path, capsys):
    import base64
    existing_b64 = base64.b64encode(b"same-password").decode()
    _patch_install(monkeypatch, tmp_path, existing_password_b64=existing_b64)

    assert cli.local_install(_install_args(password="same-password")) == 0
    assert "Local login password: same-password" in capsys.readouterr().out


def test_local_install_disables_password_gate_with_no_password_flag(monkeypatch, tmp_path, capsys):
    _patch_install(monkeypatch, tmp_path)
    assert cli.local_install(_install_args(no_password=True)) == 0
    assert "Password gate: disabled" in capsys.readouterr().out


def test_local_install_no_password_overrides_existing_password(monkeypatch, tmp_path, capsys):
    import base64
    existing_b64 = base64.b64encode(b"already-set").decode()
    _patch_install(monkeypatch, tmp_path, existing_password_b64=existing_b64)

    assert cli.local_install(_install_args(no_password=True)) == 0
    assert "Password gate: disabled" in capsys.readouterr().out


def test_local_install_does_not_print_a_misleading_password_when_accounts_survive_but_login_secret_is_gone(
    monkeypatch, tmp_path, capsys,
):
    # Issue #102's bug: the login Secret is missing (no existing_password_b64
    # below - installed_password() returns None) but at least one account
    # Secret survives. web/users.py's ensure_bootstrap_admin() only seeds a
    # password when zero accounts exist, so a freshly generated value here
    # would be written to the Secret but never actually become any account's
    # real password - "Local login password: <value>" must not be printed.
    _patch_install(monkeypatch, tmp_path, has_existing_accounts=True)
    monkeypatch.setattr(cli.secrets, "token_urlsafe", lambda n: "generated-secret")

    assert cli.local_install(_install_args()) == 0

    out = capsys.readouterr().out
    assert "Local login password:" not in out
    assert "already has account(s)" in out
    assert "NOT applied to any existing account" in out


def test_local_install_prints_the_real_password_on_a_true_first_install(monkeypatch, tmp_path, capsys):
    # No login Secret AND no account Secrets yet - a genuine first install,
    # where ensure_bootstrap_admin() will actually seed the printed value.
    # Guards against a naive "no login secret -> never trust it" fix that
    # would regress the ordinary first-install path this test covers.
    _patch_install(monkeypatch, tmp_path, has_existing_accounts=False)
    monkeypatch.setattr(cli.secrets, "token_urlsafe", lambda n: "generated-secret")

    assert cli.local_install(_install_args()) == 0

    out = capsys.readouterr().out
    assert "Local login password: generated-secret" in out


def test_local_install_raises_when_apply_fails(monkeypatch, tmp_path):
    _patch_install(monkeypatch, tmp_path, apply_returncode=1)
    with pytest.raises(cli.CommandError, match="Could not apply"):
        cli.local_install(_install_args())


def test_local_install_resolves_default_image_when_no_image_flag_given(monkeypatch, tmp_path, capsys):
    # No --image flag means args.image is None (argparse default) - install
    # must resolve it rather than passing None straight to kubectl apply.
    _patch_install(monkeypatch, tmp_path)
    digest_image = "docker.io/clusterdrill/clusterdrill@sha256:" + "d" * 64
    monkeypatch.setattr(cli, "resolve_default_image", lambda: digest_image)

    assert cli.local_install(_install_args(image=None)) == 0

    assert f"Installed {digest_image}" in capsys.readouterr().out


def test_local_install_prints_notice_when_resolution_falls_back_to_dev(monkeypatch, tmp_path, capsys):
    _patch_install(monkeypatch, tmp_path)
    monkeypatch.setattr(cli, "resolve_default_image", lambda: cli.DEV_IMAGE)

    assert cli.local_install(_install_args(image=None)) == 0

    out = capsys.readouterr().out
    assert "No published release digest" in out
    assert f"Installed {cli.DEV_IMAGE}" in out


# --- local_install_helm() (--installer=helm) -----------------------------

def _install_helm_dispatch(*, existing_password_b64: str = "", helm_returncode: int = 0, has_existing_accounts: bool = False):
    return _dispatch({
        ("minikube", "status"): lambda cmd: _cp(returncode=0, stdout="Running\n"),
        # More specific than the generic "get secret" prefix below - see
        # _install_dispatch's identical comment.
        ("kubectl", "--context", cli.PROFILE, "get", "secret", "-n", cli.NAMESPACE, "-l", cli.USER_ACCOUNT_LABEL_SELECTOR): lambda cmd: (
            _cp(returncode=0, stdout="secret/clusterdrill-user-admin\n") if has_existing_accounts else _cp(returncode=0, stdout="")
        ),
        ("kubectl", "--context", cli.PROFILE, "get", "secret"): lambda cmd: (
            _cp(returncode=0, stdout=f"{existing_password_b64}\n") if existing_password_b64 else _cp(returncode=1)
        ),
        ("kubectl", "create", "namespace"): lambda cmd: _cp(returncode=0, stdout="kind: Namespace\n"),
        ("kubectl", "create", "secret"): lambda cmd: _cp(returncode=0, stdout="kind: Secret\n"),
        ("kubectl", "--context", cli.PROFILE, "apply"): lambda cmd: _cp(returncode=0),
        ("kubectl", "--context", cli.PROFILE, "rollout"): lambda cmd: _cp(returncode=0),
        ("helm", "upgrade", "--install"): lambda cmd: _cp(returncode=helm_returncode),
    })


def _patch_install_helm(monkeypatch, *, existing_password_b64: str = "", helm_returncode: int = 0, has_existing_accounts: bool = False):
    monkeypatch.setattr(cli.shutil, "which", lambda name: f"/usr/local/bin/{name}")
    mock_run = MagicMock(side_effect=_install_helm_dispatch(
        existing_password_b64=existing_password_b64, helm_returncode=helm_returncode,
        has_existing_accounts=has_existing_accounts,
    ))
    monkeypatch.setattr(cli.subprocess, "run", mock_run)
    monkeypatch.setattr(cli, "remove_shared_cluster_user_rbac", lambda: None)
    return mock_run


def test_local_install_helm_rejects_a_non_digest_image(monkeypatch):
    _patch_install_helm(monkeypatch)
    with pytest.raises(cli.CommandError, match="requires an image pinned with @sha256"):
        cli.local_install(_install_args(image="clusterdrill:dev", installer="helm"))


def test_local_install_helm_rejects_a_mutable_tag(monkeypatch):
    _patch_install_helm(monkeypatch)
    with pytest.raises(cli.CommandError, match="requires an image pinned with @sha256"):
        cli.local_install(_install_args(image="ghcr.io/example/clusterdrill:latest", installer="helm"))


def test_local_install_helm_invokes_helm_upgrade_install_with_split_image(monkeypatch, capsys):
    mock_run = _patch_install_helm(monkeypatch)
    digest_image = "docker.io/w00dson/clusterdrill@sha256:" + "b" * 64
    assert cli.local_install(_install_args(image=digest_image, installer="helm")) == 0

    helm_calls = [c for c in mock_run.call_args_list if c.args[0][:2] == ["helm", "upgrade"]]
    assert len(helm_calls) == 1
    helm_argv = helm_calls[0].args[0]
    assert str(cli.HELM_CHART_DIR) in helm_argv
    assert "image.repository=docker.io/w00dson/clusterdrill" in " ".join(helm_argv)
    assert "image.digest=sha256:" + "b" * 64 in " ".join(helm_argv)
    assert f"auth.existingSecretName={cli.HELM_SECRET_NAME}" in " ".join(helm_argv)
    assert "Installed" in capsys.readouterr().out


def test_local_install_helm_raises_when_helm_upgrade_fails(monkeypatch):
    _patch_install_helm(monkeypatch, helm_returncode=1)
    digest_image = "docker.io/w00dson/clusterdrill@sha256:" + "c" * 64
    with pytest.raises(cli.CommandError, match="helm upgrade --install failed"):
        cli.local_install(_install_args(image=digest_image, installer="helm"))


def test_local_install_helm_does_not_print_a_misleading_password_when_accounts_survive(monkeypatch, capsys):
    # Same issue #102 drift scenario as the manifest installer's test above,
    # exercised through the Helm path since it computes/prints its own
    # password independently (see local_install_helm).
    _patch_install_helm(monkeypatch, has_existing_accounts=True)
    monkeypatch.setattr(cli.secrets, "token_urlsafe", lambda n: "generated-secret")
    digest_image = "docker.io/w00dson/clusterdrill@sha256:" + "d" * 64

    assert cli.local_install(_install_args(image=digest_image, installer="helm")) == 0

    out = capsys.readouterr().out
    assert "Local login password:" not in out
    assert "already has account(s)" in out


# --- start_service_url() / local_url() -----------------------------------
# Service-URL supervision: the first line minikube prints is treated as the
# URL, and the docker-driver tunnel process is kept alive/owned by the
# caller rather than the URL-fetch itself.

def _fake_popen(*, stdout_line: str, stderr_text: str = "", poll_sequence=None):
    process = MagicMock()
    process.stdout = MagicMock()
    process.stdout.readline.return_value = stdout_line
    process.stderr = MagicMock()
    process.stderr.read.return_value = stderr_text
    poll_values = list(poll_sequence) if poll_sequence is not None else [None]

    def poll():
        return poll_values.pop(0) if len(poll_values) > 1 else poll_values[0]

    process.poll.side_effect = poll
    return process


def test_start_service_url_returns_loopback_port_forward_url(monkeypatch):
    process = _fake_popen(stdout_line="Forwarding from 127.0.0.1:54321 -> 8000\n")
    monkeypatch.setattr(cli.subprocess, "Popen", MagicMock(return_value=process))

    returned_process, url = cli.start_service_url()

    assert url == "http://127.0.0.1:54321"
    assert returned_process is process


def test_start_service_url_raises_when_no_url_and_reports_stderr(monkeypatch):
    process = _fake_popen(stdout_line="", stderr_text="minikube: profile not found\n")
    monkeypatch.setattr(cli.subprocess, "Popen", MagicMock(return_value=process))

    with pytest.raises(cli.CommandError, match="profile not found"):
        cli.start_service_url()


def test_local_url_requires_running_profile(monkeypatch):
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(return_value=_cp(returncode=1)))
    with pytest.raises(cli.CommandError, match="is not running"):
        cli.local_url(argparse.Namespace())


def test_local_url_waits_on_open_tunnel(monkeypatch, capsys):
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(return_value=_cp(returncode=0, stdout="Running\n")))
    process = _fake_popen(stdout_line="Forwarding from 127.0.0.1:54321 -> 8000\n")
    process.wait.return_value = 0
    monkeypatch.setattr(cli.subprocess, "Popen", MagicMock(return_value=process))

    assert cli.local_url(argparse.Namespace()) == 0
    out = capsys.readouterr().out
    assert "http://127.0.0.1:54321" in out
    assert "Keeping the Minikube service tunnel open" in out
    process.wait.assert_called_once()


def test_local_url_returns_immediately_when_tunnel_already_exited(monkeypatch, capsys):
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(return_value=_cp(returncode=0, stdout="Running\n")))
    process = _fake_popen(stdout_line="Forwarding from 127.0.0.1:54321 -> 8000\n", poll_sequence=[0])
    monkeypatch.setattr(cli.subprocess, "Popen", MagicMock(return_value=process))

    assert cli.local_url(argparse.Namespace()) == 0
    process.wait.assert_not_called()


def test_local_url_terminates_tunnel_on_keyboard_interrupt(monkeypatch, capsys):
    monkeypatch.setattr(cli.subprocess, "run", MagicMock(return_value=_cp(returncode=0, stdout="Running\n")))
    process = _fake_popen(stdout_line="Forwarding from 127.0.0.1:54321 -> 8000\n")
    process.wait.side_effect = KeyboardInterrupt()
    monkeypatch.setattr(cli.subprocess, "Popen", MagicMock(return_value=process))

    assert cli.local_url(argparse.Namespace()) == 130
    process.terminate.assert_called_once()


# --- local_destroy() ----------------------------------------------------
# Safe destroy confirmation: only the named, disposable profile is ever
# deleted, and only after an explicit "y"/"yes" unless --yes was passed.

def test_local_destroy_skips_confirmation_with_yes_flag(monkeypatch, capsys):
    mock_run = MagicMock(return_value=_cp(returncode=0))
    monkeypatch.setattr(cli.subprocess, "run", mock_run)

    assert cli.local_destroy(argparse.Namespace(yes=True)) == 0

    mock_run.assert_called_once_with(["minikube", "delete", "--profile", cli.PROFILE], text=True, capture_output=False, check=True)
    assert f"Deleted only Minikube profile '{cli.PROFILE}'" in capsys.readouterr().out


def test_local_destroy_cancels_on_declined_confirmation(monkeypatch, capsys):
    mock_run = MagicMock(return_value=_cp(returncode=0))
    monkeypatch.setattr(cli.subprocess, "run", mock_run)
    monkeypatch.setattr("builtins.input", lambda _prompt: "n")

    assert cli.local_destroy(argparse.Namespace(yes=False)) == 0

    mock_run.assert_not_called()
    assert "Cancelled." in capsys.readouterr().out


def test_local_destroy_proceeds_on_confirmed_input(monkeypatch, capsys):
    mock_run = MagicMock(return_value=_cp(returncode=0))
    monkeypatch.setattr(cli.subprocess, "run", mock_run)
    monkeypatch.setattr("builtins.input", lambda _prompt: "y")

    assert cli.local_destroy(argparse.Namespace(yes=False)) == 0

    mock_run.assert_called_once()
    assert mock_run.call_args.args[0] == ["minikube", "delete", "--profile", cli.PROFILE]


# --- main() / build_parser() wiring --------------------------------------

def test_main_prints_command_error_and_returns_1(monkeypatch, capsys):
    monkeypatch.setattr(cli.shutil, "which", lambda name: None)
    exit_code = cli.main(["local", "install"])
    assert exit_code == 1
    err = capsys.readouterr().err
    assert err.startswith("clusterdrill: ")


def test_build_parser_routes_local_doctor():
    # Argument parsing/routing only - the handler is not invoked here, so
    # no subprocess/binary mocking is needed (see local_doctor's own tests
    # above for its actual behavior).
    args = cli.build_parser().parse_args(["local", "doctor"])
    assert args.handler is cli.local_doctor


def test_build_parser_local_install_defaults():
    # None means "resolve the release-pinned image at install time" - see
    # resolve_default_image() and its local_install() call site.
    args = cli.build_parser().parse_args(["local", "install"])
    assert args.image is None
    assert args.no_password is False
    assert args.password is None
    assert args.timeout == "5m"
    assert args.handler is cli.local_install


def test_build_parser_local_install_rejects_password_and_no_password_together():
    with pytest.raises(SystemExit):
        cli.build_parser().parse_args(["local", "install", "--password", "x", "--no-password"])
