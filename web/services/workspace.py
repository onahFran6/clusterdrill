"""Display the canonical workspace without exporting files or credentials."""
from __future__ import annotations

import os
import shlex
from pathlib import Path

import users
from grading_client import namespaced_id


def workspace_context(qid: str, user_id: str | None, workdir: Path) -> dict:
    namespace = namespaced_id(qid, user_id)
    # A browser user's kubeconfig context cannot be inferred from the
    # application's in-cluster kubeconfig. Only use explicitly supplied data.
    context = os.environ.get("CLUSTERDRILL_PRACTICE_CONTEXT", "")
    pod = os.environ.get("CLUSTERDRILL_POD_NAME", "")
    pod_namespace = os.environ.get("CLUSTERDRILL_POD_NAMESPACE", "")
    container = os.environ.get("CLUSTERDRILL_CONTAINER", "")
    owner = users.single_user_mode()
    prefix = ["kubectl", "--context", context or "<practice-context>"]
    command = None
    if owner and pod and pod_namespace and container:
        shell = f"cd {shlex.quote(str(workdir))} && exec bash"
        command = shlex.join([*prefix, "-n", pod_namespace, "exec", "-it", f"pod/{pod}", "-c", container,
                              "--", "sh", "-c", shell])
    try:
        files = sorted(entry.name + ("/" if entry.is_dir() else "") for entry in workdir.iterdir())
    except OSError:
        files = []
    return {
        "namespace": namespace,
        "path": str(workdir),
        "location": f"Pod {pod}, container {container}" if pod and container else "Application process filesystem",
        "context": context,
        "owner": owner,
        "kubectl_command": shlex.join([*prefix, "-n", namespace, "get", "pods"]) if owner else None,
        "shell_command": command,
        "files": files,
    }
