"""Per-user Kubernetes RBAC, provisioned
alongside each user account - the piece that makes a logged-in user's
*terminal* actually unable to read or modify another user's namespace.
Everything through Phase 5 isolated *where* each user's resources live
(separate namespaces, separate quotas); every terminal session still ran
with the app's own cluster-admin kubeconfig until now, so alice's shell
could still run `kubectl get pods -n <bobs-namespace>` directly - only
Kubernetes RBAC actually closes that.

Design:
    - One ServiceAccount per user, living in a dedicated system namespace
      (kube_json.SYSTEM_NAMESPACE) - not in any of the user's own question namespaces,
      since those get torn down/recreated constantly (full_reset) and the
      identity backing a user's terminal needs to outlive any one of them.
    - A long-lived Secret-bound token (the pre-1.24 style, not a
      TokenRequest-API bounded token) - deliberate simplification for a
      lab tool where a terminal session can run for hours: a bounded token
      would need active refresh wired into ttyd's spawned shell, which is
      real complexity for a threat model (a fellow admin-provisioned lab
      user, not an untrusted public actor) that doesn't need it.
    - Per-namespace access (Role+RoleBinding) is granted by lib/grading.sh's
      grant_user_namespace_access, called from every question's setup.sh -
      not from here, since it needs to happen namespace-by-namespace as
      each one is created, not once per user.
    - A single shared ClusterRole (CLUSTER_ROLE_NAME) covers the small set
      of cluster-scoped kinds some questions legitimately need to create
      (ClusterRole/ClusterRoleBinding/PersistentVolume/StorageClass/CRD,
      plus read-only Node access for the node-debugging question) -
      checked directly against every question in the bank. Deliberately
      does NOT include `namespaces` (so a user's terminal can't enumerate
      other users' namespaces) or a wildcard across all resources (which
      would also grant cross-namespace access to namespaced kinds like
      pods/secrets - the opposite of the point). Known, accepted
      limitation: these specific cluster-scoped kinds remain visible
      across users, since Kubernetes RBAC has no way to scope "only the
      ones you created" for a cluster-scoped kind without per-object
      resourceNames bookkeeping this pass deliberately doesn't take on.
"""
from __future__ import annotations

import base64
import json
import logging
import os
import subprocess
import time
from pathlib import Path
from typing import Optional

import yaml
from kube_json import SYSTEM_NAMESPACE, kubectl_apply_json, kubectl_delete, kubectl_get_json

logger = logging.getLogger("clusterdrill.rbac")

CLUSTER_ROLE_NAME = "clusterdrill-cluster-scoped-access"
KUBECTL_TIMEOUT_SECONDS = 15
TOKEN_POLL_ATTEMPTS = 20
TOKEN_POLL_INTERVAL_SECONDS = 0.3

# issue #122 (M7): worker-node terminal tabs. Reads the same env var
# ttyd_manager.MAX_TERMINAL_TABS does (rather than importing that constant
# directly, which would create a real circular import - ttyd_manager
# already imports this module at load time), so the two stay in sync
# without needing to be. Used only to pre-provision resourceNames for
# every tab slot a user could ever open - see the node-debug Role below.
NODE_DEBUG_TAB_CAP = int(os.environ.get("CLUSTERDRILL_TERMINAL_MAX_TABS", "5"))

KUBECONFIG_DIR = Path.home() / ".clusterdrill" / "kubeconfigs"


def _service_account_name(user_id: str) -> str:
    return user_id


def _token_secret_name(user_id: str) -> str:
    return f"{user_id}-token"


def _cluster_role_binding_name(user_id: str) -> str:
    return f"clusterdrill-cluster-scoped-access-{user_id}"


def _node_debug_role_name(user_id: str) -> str:
    return f"clusterdrill-node-debug-{user_id}"


def delete_debug_pod(user_id: str, tab_id: int) -> None:
    """Deletes one (user_id, tab_id) worker-node terminal tab's debug pod,
    if one exists - a harmless no-op (--ignore-not-found) for a
    control-plane tab, which never creates one. Called whenever that tab's
    tmux session is killed (ttyd_manager.kill_user_tmux_sessions /
    kill_all_tmux_sessions): the tmux session dying does not, by itself,
    stop the remote debug pod - it's a separate Kubernetes object,
    unaffected by killing the local kubectl process that was attached to
    it - so without this, a debug pod accumulates every time its owning
    tab's session ends (idle timeout, account deletion, or an app
    restart)."""
    kubectl_delete("pod", debug_pod_name(user_id, tab_id), "-n", SYSTEM_NAMESPACE)


def debug_pod_name(user_id: str, tab_id: int) -> str:
    """The deterministic name of the debug pod a worker-node terminal tab
    creates (ttyd_manager._shell_command) - deterministic and namespaced
    per (user_id, tab_id) specifically so the resourceNames-scoped rules
    below can name it in advance, and so a reconnect/reload reuses the
    same pod instead of creating a second one. Also what
    delete_user_service_account below cleans up by name."""
    return f"clusterdrill-node-debug-{user_id}-{tab_id}"


def user_kubeconfig_path(user_id: str) -> Path:
    return KUBECONFIG_DIR / f"{user_id}.yaml"


def ensure_system_bootstrap() -> None:
    """Idempotent, called once on every app startup (app.py's lifespan,
    first - before users.ensure_bootstrap_admin, which needs this
    namespace to already exist): creates SYSTEM_NAMESPACE and the one
    shared ClusterRole every user's
    ClusterRoleBinding points at. Best-effort - a failure here (e.g. no
    cluster reachable yet) disables per-user terminal isolation for this
    run rather than crashing startup, matching this app's existing
    degrade-don't-crash posture for cluster-dependent optional setup.
    """
    kubectl_apply_json({
        "apiVersion": "v1",
        "kind": "Namespace",
        "metadata": {"name": SYSTEM_NAMESPACE},
    })
    kubectl_apply_json({
        "apiVersion": "rbac.authorization.k8s.io/v1",
        "kind": "ClusterRole",
        "metadata": {"name": CLUSTER_ROLE_NAME},
        "rules": [
            {
                "apiGroups": ["rbac.authorization.k8s.io"],
                "resources": ["clusterroles", "clusterrolebindings"],
                "verbs": ["*"],
            },
            {"apiGroups": [""], "resources": ["persistentvolumes"], "verbs": ["*"]},
            {"apiGroups": ["storage.k8s.io"], "resources": ["storageclasses"], "verbs": ["*"]},
            {
                "apiGroups": ["apiextensions.k8s.io"],
                "resources": ["customresourcedefinitions"],
                "verbs": ["*"],
            },
            # Read-only: q107-13-debug-node-shell needs `kubectl get nodes`
            # to find the node name for `kubectl debug node/<name>` - the
            # debug pod itself lands in the candidate's own namespace
            # (covered by grant_user_namespace_access), so nothing beyond
            # get/list is needed here.
            {"apiGroups": [""], "resources": ["nodes"], "verbs": ["get", "list"]},
        ],
    })


def _poll_service_account_token(user_id: str) -> Optional[str]:
    """Kubernetes populates a kubernetes.io/service-account-token Secret's
    data.token asynchronously after creation - a short poll loop, not an
    immediate read, matching that (typically populates within ~1s)."""
    secret_name = _token_secret_name(user_id)
    for _ in range(TOKEN_POLL_ATTEMPTS):
        obj = kubectl_get_json("secret", secret_name, "-n", SYSTEM_NAMESPACE)
        if obj is not None:
            token_b64 = obj.get("data", {}).get("token")
            if token_b64:
                return base64.b64decode(token_b64).decode("ascii")
        time.sleep(TOKEN_POLL_INTERVAL_SECONDS)
    return None


def _current_cluster_info() -> Optional[dict]:
    """Reads the *app's own* admin kubeconfig's current-context cluster
    (server URL + CA data) - reused as the `clusters:` entry in every
    per-user kubeconfig this module writes, since every user talks to the
    same API server, just as a different identity. `--raw` so a CA
    referenced by file path (common on minikube) is resolved and inlined
    rather than left as a path that may not resolve the same way inside
    ttyd's spawned shell environment.
    """
    try:
        proc = subprocess.run(
            ["kubectl", "config", "view", "--minify", "--raw", "-o", "json"],
            capture_output=True, text=True, timeout=KUBECTL_TIMEOUT_SECONDS,
        )
    except (subprocess.TimeoutExpired, OSError):
        return None
    if proc.returncode != 0:
        return None
    try:
        config = json.loads(proc.stdout)
        return config["clusters"][0]["cluster"]
    except (json.JSONDecodeError, KeyError, IndexError):
        return None


def _write_kubeconfig(user_id: str, token: str, cluster: dict) -> Path:
    server = cluster.get("server", "")
    ca_data = cluster.get("certificate-authority-data")
    cluster_entry: dict = {"server": server}
    if ca_data:
        cluster_entry["certificate-authority-data"] = ca_data
    else:
        # No CA data at all (e.g. a dev cluster with TLS verification
        # disabled) - matches the admin kubeconfig's own trust posture
        # rather than silently downgrading security beyond what the app's
        # own connection already accepts.
        cluster_entry["insecure-skip-tls-verify"] = True

    kubeconfig = {
        "apiVersion": "v1",
        "kind": "Config",
        "clusters": [{"name": "clusterdrill", "cluster": cluster_entry}],
        "users": [{"name": user_id, "user": {"token": token}}],
        "contexts": [{
            "name": "clusterdrill",
            "context": {"cluster": "clusterdrill", "user": user_id},
        }],
        "current-context": "clusterdrill",
    }

    KUBECONFIG_DIR.mkdir(parents=True, exist_ok=True)
    path = user_kubeconfig_path(user_id)
    path.write_text(yaml.safe_dump(kubeconfig))
    path.chmod(0o600)
    return path


def ensure_user_service_account(user_id: str) -> bool:
    """Idempotent: creates the ServiceAccount/token Secret/ClusterRoleBinding
    (if missing) and (re)writes that user's kubeconfig file. Safe to call on
    every app startup (for every existing account) and every time an admin
    creates a new account - re-running against an already-provisioned user
    is a no-op except refreshing the kubeconfig file, which is cheap.
    Returns False (best-effort, never raises) if the cluster wasn't
    reachable or the token never populated - ttyd_manager falls back to the
    app's own kubeconfig in that case rather than failing the whole
    terminal, logged loudly so it doesn't fail silently.
    """
    sa_name = _service_account_name(user_id)
    ok = kubectl_apply_json({
        "apiVersion": "v1",
        "kind": "ServiceAccount",
        "metadata": {"name": sa_name, "namespace": SYSTEM_NAMESPACE},
    })
    ok = kubectl_apply_json({
        "apiVersion": "v1",
        "kind": "Secret",
        "type": "kubernetes.io/service-account-token",
        "metadata": {
            "name": _token_secret_name(user_id),
            "namespace": SYSTEM_NAMESPACE,
            "annotations": {"kubernetes.io/service-account.name": sa_name},
        },
    }) and ok
    ok = kubectl_apply_json({
        "apiVersion": "rbac.authorization.k8s.io/v1",
        "kind": "ClusterRoleBinding",
        "metadata": {"name": _cluster_role_binding_name(user_id)},
        "subjects": [{"kind": "ServiceAccount", "name": sa_name, "namespace": SYSTEM_NAMESPACE}],
        "roleRef": {"kind": "ClusterRole", "name": CLUSTER_ROLE_NAME, "apiGroup": "rbac.authorization.k8s.io"},
    }) and ok
    # issue #122: a worker-node terminal tab creates a debug pod (see
    # ttyd_manager._shell_command) in SYSTEM_NAMESPACE, named
    # deterministically per (user_id, tab_id) - debug_pod_name(). "create"
    # can't be resourceNames-scoped (Kubernetes RBAC only supports
    # resourceNames on verbs that act on an already-existing object), so
    # any user with this Role can create a pod in this shared namespace;
    # get/delete/exec are resourceNames-scoped to only the exact pod names
    # this user could ever create, pre-provisioned up to
    # NODE_DEBUG_TAB_CAP - so alice's Role can never see, exec into, or
    # delete a pod actually named after bob, even though they share this
    # one namespace. Namespace-scoped so it can never touch pods outside
    # SYSTEM_NAMESPACE (in particular, never a candidate's own question
    # namespaces).
    debug_pod_names = [debug_pod_name(user_id, tab_id) for tab_id in range(1, NODE_DEBUG_TAB_CAP + 1)]
    ok = kubectl_apply_json({
        "apiVersion": "rbac.authorization.k8s.io/v1",
        "kind": "Role",
        "metadata": {"name": _node_debug_role_name(user_id), "namespace": SYSTEM_NAMESPACE},
        "rules": [
            {"apiGroups": [""], "resources": ["pods"], "verbs": ["create"]},
            {
                "apiGroups": [""], "resources": ["pods"],
                "verbs": ["get", "watch", "delete"], "resourceNames": debug_pod_names,
            },
            {
                "apiGroups": [""], "resources": ["pods/exec"],
                "verbs": ["create"], "resourceNames": debug_pod_names,
            },
        ],
    }) and ok
    ok = kubectl_apply_json({
        "apiVersion": "rbac.authorization.k8s.io/v1",
        "kind": "RoleBinding",
        "metadata": {"name": _node_debug_role_name(user_id), "namespace": SYSTEM_NAMESPACE},
        "subjects": [{"kind": "ServiceAccount", "name": sa_name, "namespace": SYSTEM_NAMESPACE}],
        "roleRef": {"kind": "Role", "name": _node_debug_role_name(user_id), "apiGroup": "rbac.authorization.k8s.io"},
    }) and ok
    if not ok:
        logger.warning("RBAC provisioning failed for user %s (kubectl apply error)", user_id)
        return False

    token = _poll_service_account_token(user_id)
    if token is None:
        logger.warning("RBAC provisioning: token never populated for user %s", user_id)
        return False

    cluster = _current_cluster_info()
    if cluster is None:
        logger.warning("RBAC provisioning: could not read cluster info for user %s's kubeconfig", user_id)
        return False

    _write_kubeconfig(user_id, token, cluster)
    return True


def delete_user_service_account(user_id: str) -> None:
    """Tears down everything ensure_user_service_account created, plus the
    kubeconfig file - called when an admin deletes an account
    (routers/admin_router.py). The Role/RoleBindings this user's own
    question namespaces accumulated (grant_user_namespace_access) are left
    in place but become inert (their ServiceAccount subject no longer
    exists, so authentication - not just authorization - fails); not worth
    a namespace-by-namespace sweep for objects that stop mattering the
    moment the identity behind them is gone.

    The node-debug Role/RoleBinding and any live debug pods (issue #122)
    are different: they all live in this one SYSTEM_NAMESPACE, so cleaning
    them up here is cheap - and unlike an inert RoleBinding, a live debug
    pod is a running, privileged (hostPID/hostNetwork) process actually
    consuming cluster resources, not just a leftover permission grant, so
    it gets deleted outright rather than left to go inert.
    """
    kubectl_delete("serviceaccount", _service_account_name(user_id), "-n", SYSTEM_NAMESPACE)
    kubectl_delete("secret", _token_secret_name(user_id), "-n", SYSTEM_NAMESPACE)
    kubectl_delete("clusterrolebinding", _cluster_role_binding_name(user_id))
    kubectl_delete("role", _node_debug_role_name(user_id), "-n", SYSTEM_NAMESPACE)
    kubectl_delete("rolebinding", _node_debug_role_name(user_id), "-n", SYSTEM_NAMESPACE)
    for tab_id in range(1, NODE_DEBUG_TAB_CAP + 1):
        delete_debug_pod(user_id, tab_id)
    user_kubeconfig_path(user_id).unlink(missing_ok=True)
