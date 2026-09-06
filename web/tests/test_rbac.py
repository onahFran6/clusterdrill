"""rbac.py: per-user ServiceAccount/kubeconfig provisioning. Mocks kube_json's kubectl_get_json/kubectl_apply_json/
kubectl_delete directly with an in-memory fake, same approach as
tests/test_users.py - and mocks subprocess.run (used directly here for
`kubectl config view`) and time.sleep (token polling) so this never touches
a real cluster or slows the suite down.
"""
from __future__ import annotations

import base64
import json
from unittest.mock import MagicMock

import pytest
import rbac


class FakeCluster:
    def __init__(self):
        self.objects: dict[tuple[str, str], dict] = {}

    def get_json(self, *args: str):
        kind, name = args[0], args[1]
        return self.objects.get((kind, name))

    def apply_json(self, obj: dict) -> bool:
        kind = obj["kind"].lower()
        name = obj["metadata"]["name"]
        self.objects[(kind, name)] = obj
        return True

    def delete(self, *args: str) -> bool:
        kind, name = args[0], args[1]
        self.objects.pop((kind, name), None)
        return True


@pytest.fixture
def cluster(monkeypatch):
    fake = FakeCluster()
    monkeypatch.setattr(rbac, "kubectl_get_json", fake.get_json)
    monkeypatch.setattr(rbac, "kubectl_apply_json", fake.apply_json)
    monkeypatch.setattr(rbac, "kubectl_delete", fake.delete)
    monkeypatch.setattr(rbac.time, "sleep", lambda seconds: None)
    return fake


@pytest.fixture(autouse=True)
def isolate_kubeconfig_dir(monkeypatch, tmp_path):
    monkeypatch.setattr(rbac, "KUBECONFIG_DIR", tmp_path / "kubeconfigs")


def _mock_token(monkeypatch, token: str = "fake-token-value"):
    """Stubs out the token-population poll entirely - ensure_user_service_
    account's own kubectl_apply_json call for the Secret always writes an
    object with no data.token (matching the real Kubernetes flow: the
    control plane populates it *asynchronously* after the apply, which a
    synchronous FakeCluster can't naturally reproduce). See
    test_poll_service_account_token_* below for direct coverage of the
    polling logic itself, exercised without going through the full
    ensure_user_service_account flow."""
    monkeypatch.setattr(rbac, "_poll_service_account_token", lambda user_id: token)


def _mock_cluster_info(monkeypatch, server="https://127.0.0.1:6443", ca_data="ZmFrZS1jYQ=="):
    result = json.dumps({"clusters": [{"cluster": {"server": server, "certificate-authority-data": ca_data}}]})
    mock_run = MagicMock(return_value=MagicMock(returncode=0, stdout=result))
    monkeypatch.setattr(rbac.subprocess, "run", mock_run)
    return mock_run


# --- ensure_system_bootstrap ---------------------------------------------

def test_ensure_system_bootstrap_creates_namespace_and_cluster_role(cluster):
    rbac.ensure_system_bootstrap()
    assert ("namespace", rbac.SYSTEM_NAMESPACE) in cluster.objects
    assert ("clusterrole", rbac.CLUSTER_ROLE_NAME) in cluster.objects


def test_cluster_role_does_not_grant_namespaces_or_wildcard(cluster):
    rbac.ensure_system_bootstrap()
    cluster_role = cluster.objects[("clusterrole", rbac.CLUSTER_ROLE_NAME)]
    for rule in cluster_role["rules"]:
        assert "namespaces" not in rule["resources"]
        # No rule anywhere grants a bare wildcard across all resources -
        # that would also cover namespaced kinds cluster-wide (pods,
        # secrets, ...), defeating per-namespace isolation entirely.
        assert rule["resources"] != ["*"]


# --- ensure_user_service_account -----------------------------------------

def test_ensure_user_service_account_creates_sa_secret_and_binding(cluster, monkeypatch):
    _mock_cluster_info(monkeypatch)
    _mock_token(monkeypatch)
    ok = rbac.ensure_user_service_account("alice")
    assert ok is True
    assert ("serviceaccount", "alice") in cluster.objects
    assert ("secret", "alice-token") in cluster.objects
    assert ("clusterrolebinding", "clusterdrill-cluster-scoped-access-alice") in cluster.objects


# --- node-debug Role/RoleBinding (issue #122 / M7) -------------------------

def test_ensure_user_service_account_creates_node_debug_role_and_binding(cluster, monkeypatch):
    _mock_cluster_info(monkeypatch)
    _mock_token(monkeypatch)
    rbac.ensure_user_service_account("alice")
    assert ("role", "clusterdrill-node-debug-alice") in cluster.objects
    assert ("rolebinding", "clusterdrill-node-debug-alice") in cluster.objects


def test_node_debug_role_scopes_get_delete_exec_to_this_users_own_pod_names(cluster, monkeypatch):
    _mock_cluster_info(monkeypatch)
    _mock_token(monkeypatch)
    rbac.ensure_user_service_account("alice")
    role = cluster.objects[("role", "clusterdrill-node-debug-alice")]

    expected_names = [rbac.debug_pod_name("alice", tab_id) for tab_id in range(1, rbac.NODE_DEBUG_TAB_CAP + 1)]
    by_resource_and_verbs = {(tuple(r["resources"]), tuple(sorted(r["verbs"]))): r for r in role["rules"]}

    create_rule = by_resource_and_verbs[(("pods",), ("create",))]
    assert "resourceNames" not in create_rule  # create can never be resourceNames-scoped

    read_rule = by_resource_and_verbs[(("pods",), ("delete", "get", "watch"))]
    assert read_rule["resourceNames"] == expected_names

    exec_rule = by_resource_and_verbs[(("pods/exec",), ("create",))]
    assert exec_rule["resourceNames"] == expected_names


def test_node_debug_role_names_never_leak_across_users(cluster, monkeypatch):
    _mock_cluster_info(monkeypatch)
    _mock_token(monkeypatch)
    rbac.ensure_user_service_account("alice")
    rbac.ensure_user_service_account("bob")

    alice_role = cluster.objects[("role", "clusterdrill-node-debug-alice")]
    bob_role = cluster.objects[("role", "clusterdrill-node-debug-bob")]
    alice_names = next(r["resourceNames"] for r in alice_role["rules"] if "resourceNames" in r)
    bob_names = next(r["resourceNames"] for r in bob_role["rules"] if "resourceNames" in r)

    assert set(alice_names).isdisjoint(bob_names)
    assert all("alice" in name for name in alice_names)
    assert all("bob" in name for name in bob_names)


def test_debug_pod_name_is_deterministic_per_user_and_tab():
    assert rbac.debug_pod_name("alice", 2) == rbac.debug_pod_name("alice", 2)
    assert rbac.debug_pod_name("alice", 1) != rbac.debug_pod_name("alice", 2)
    assert rbac.debug_pod_name("alice", 1) != rbac.debug_pod_name("bob", 1)


def test_delete_debug_pod_deletes_by_name(cluster):
    cluster.objects[("pod", rbac.debug_pod_name("alice", 1))] = {"kind": "Pod"}
    rbac.delete_debug_pod("alice", 1)
    assert ("pod", rbac.debug_pod_name("alice", 1)) not in cluster.objects


def test_delete_debug_pod_missing_pod_is_a_noop(cluster):
    rbac.delete_debug_pod("alice", 1)  # must not raise


def test_ensure_user_service_account_writes_kubeconfig(cluster, monkeypatch):
    _mock_cluster_info(monkeypatch, server="https://127.0.0.1:6443")
    _mock_token(monkeypatch, token="alice-token-value")
    rbac.ensure_user_service_account("alice")

    path = rbac.user_kubeconfig_path("alice")
    assert path.exists()
    import yaml
    config = yaml.safe_load(path.read_text())
    assert config["clusters"][0]["cluster"]["server"] == "https://127.0.0.1:6443"
    assert config["users"][0]["user"]["token"] == "alice-token-value"
    assert config["current-context"] == "clusterdrill"


def test_ensure_user_service_account_false_when_token_never_populates(cluster, monkeypatch):
    _mock_cluster_info(monkeypatch)
    # No _seed_token call - token stays unpopulated forever.
    ok = rbac.ensure_user_service_account("alice")
    assert ok is False
    assert not rbac.user_kubeconfig_path("alice").exists()


def test_ensure_user_service_account_false_when_cluster_info_unreadable(cluster, monkeypatch):
    monkeypatch.setattr(rbac.subprocess, "run", MagicMock(return_value=MagicMock(returncode=1, stdout="")))
    _mock_token(monkeypatch)
    ok = rbac.ensure_user_service_account("alice")
    assert ok is False


def test_ensure_user_service_account_idempotent(cluster, monkeypatch):
    _mock_cluster_info(monkeypatch)
    _mock_token(monkeypatch)
    assert rbac.ensure_user_service_account("alice") is True
    assert rbac.ensure_user_service_account("alice") is True


# --- delete_user_service_account ------------------------------------------

def test_delete_user_service_account_removes_everything(cluster, monkeypatch):
    _mock_cluster_info(monkeypatch)
    _mock_token(monkeypatch)
    rbac.ensure_user_service_account("alice")
    assert rbac.user_kubeconfig_path("alice").exists()
    # A live debug pod (issue #122) - not just permission grants - must
    # also actually be torn down, not left running with no owner.
    cluster.objects[("pod", rbac.debug_pod_name("alice", 1))] = {"kind": "Pod"}

    rbac.delete_user_service_account("alice")

    assert ("serviceaccount", "alice") not in cluster.objects
    assert ("secret", "alice-token") not in cluster.objects
    assert ("clusterrolebinding", "clusterdrill-cluster-scoped-access-alice") not in cluster.objects
    assert ("role", "clusterdrill-node-debug-alice") not in cluster.objects
    assert ("rolebinding", "clusterdrill-node-debug-alice") not in cluster.objects
    assert ("pod", rbac.debug_pod_name("alice", 1)) not in cluster.objects
    assert not rbac.user_kubeconfig_path("alice").exists()


def test_delete_user_service_account_missing_kubeconfig_is_a_noop(cluster):
    # Never provisioned in the first place - must not raise.
    rbac.delete_user_service_account("nobody")


# --- kubeconfig fallback when no CA data is present ------------------------

def test_kubeconfig_falls_back_to_insecure_skip_tls_verify_without_ca_data(cluster, monkeypatch):
    _mock_cluster_info(monkeypatch, ca_data=None)
    _mock_token(monkeypatch)
    rbac.ensure_user_service_account("alice")

    import yaml
    config = yaml.safe_load(rbac.user_kubeconfig_path("alice").read_text())
    cluster_entry = config["clusters"][0]["cluster"]
    assert cluster_entry.get("insecure-skip-tls-verify") is True
    assert "certificate-authority-data" not in cluster_entry


# --- _poll_service_account_token (direct, not via ensure_user_service_account) --

def test_poll_service_account_token_returns_decoded_token(cluster):
    cluster.objects[("secret", "alice-token")] = {
        "data": {"token": base64.b64encode(b"real-token-value").decode()},
    }
    assert rbac._poll_service_account_token("alice") == "real-token-value"


def test_poll_service_account_token_none_when_secret_never_appears(cluster):
    assert rbac._poll_service_account_token("alice") is None


def test_poll_service_account_token_none_when_data_token_missing(cluster):
    cluster.objects[("secret", "alice-token")] = {"data": {}}
    assert rbac._poll_service_account_token("alice") is None
