"""Server-side Kubernetes topology discovery for local eligibility checks."""
from __future__ import annotations

import json
import logging
import subprocess
from typing import Optional

logger = logging.getLogger("clusterdrill.topology")

# Fixed lookup table, kept in sync with
# clusterdrill/cli.py's PROVISIONER_TO_STORAGE_PROFILE (that one drives
# `local doctor`'s report; this one drives which questions the running app
# actually shows). Anything else maps to None ("unknown"), which fails
# closed for any question that declares a storage_profile requirement.
_PROVISIONER_TO_STORAGE_PROFILE = {
    "k8s.io/minikube-hostpath": "minikube",
    "rancher.io/local-path": "local-path",
}


def storage_profile() -> Optional[str]:
    """Read the cluster's default StorageClass and map its provisioner to a
    named storage profile, using the pod's ServiceAccount - same pattern
    and same fail-closed reasoning as node_count() above, except the
    closed value here is None ("unknown") rather than zero, since
    Question.is_storage_eligible_for already treats None as "no declared
    requirement can be confirmed satisfied" for questions that need one.
    """
    try:
        result = subprocess.run(
            ["kubectl", "get", "storageclass", "-o", "json"],
            capture_output=True,
            text=True,
            timeout=15,
            check=True,
        )
        items = json.loads(result.stdout).get("items", [])
    except (OSError, subprocess.SubprocessError, json.JSONDecodeError) as exc:
        logger.warning("could not determine default StorageClass: %s", exc)
        return None
    if not isinstance(items, list):
        return None
    for item in items:
        annotations = (item.get("metadata") or {}).get("annotations") or {}
        if annotations.get("storageclass.kubernetes.io/is-default-class") == "true":
            return _PROVISIONER_TO_STORAGE_PROFILE.get(item.get("provisioner"))
    return None


def node_count() -> int:
    """Read the actual cluster node count using the pod's ServiceAccount.

    An unavailable API fails closed as zero eligible questions. A learner must
    never get a question merely because the browser claimed a topology.
    """
    try:
        result = subprocess.run(
            ["kubectl", "get", "nodes", "-o", "json"],
            capture_output=True,
            text=True,
            timeout=15,
            check=True,
        )
        items = json.loads(result.stdout).get("items", [])
        return len(items) if isinstance(items, list) else 0
    except (OSError, subprocess.SubprocessError, json.JSONDecodeError) as exc:
        logger.warning("could not determine Kubernetes node count: %s", exc)
        return 0
