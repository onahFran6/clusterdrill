"""Shared low-level kubectl JSON get/apply/delete helpers, for any module
that persists app state as a Kubernetes object instead of a database -
"store progress as Kubernetes objects, not database rows." profile_store.py
and users.py both need the identical get/apply
shape, so it's factored out here rather than duplicated a second time.

State lives in ConfigMaps (profile_store.py) and Secrets (users.py) in
SYSTEM_NAMESPACE, not in a project-owned CustomResourceDefinition: no
domain is confirmed for a project-owned CRD group or label/annotation
prefix (see practice-bank/docs/adr/0001-naming-standard.md), so this app
has no CRD of its own. configmap_payload/secret_payload/decode_payload
below are the small, generic wrapper this app uses instead - a single
JSON-encoded blob under one data key, so the object shape a caller works
with (a plain dict, get/apply/decode) stays the same as before.
"""
from __future__ import annotations

import base64
import json
import subprocess

KUBECTL_TIMEOUT_SECONDS = 15
SYSTEM_NAMESPACE = "clusterdrill-system"
_PAYLOAD_KEY = "data.json"


def kubectl_get_json(*args: str) -> dict | None:
    try:
        proc = subprocess.run(
            ["kubectl", "get", *args, "-o", "json"],
            capture_output=True, text=True, timeout=KUBECTL_TIMEOUT_SECONDS,
        )
    except (subprocess.TimeoutExpired, OSError):
        return None
    if proc.returncode != 0:
        return None
    try:
        return json.loads(proc.stdout)
    except json.JSONDecodeError:
        return None


def kubectl_apply_json(obj: dict) -> bool:
    try:
        proc = subprocess.run(
            ["kubectl", "apply", "-f", "-"],
            input=json.dumps(obj),
            capture_output=True, text=True, timeout=KUBECTL_TIMEOUT_SECONDS,
        )
    except (subprocess.TimeoutExpired, OSError):
        return False
    return proc.returncode == 0


def kubectl_delete(*args: str) -> bool:
    try:
        proc = subprocess.run(
            ["kubectl", "delete", *args, "--ignore-not-found=true"],
            capture_output=True, text=True, timeout=KUBECTL_TIMEOUT_SECONDS,
        )
    except (subprocess.TimeoutExpired, OSError):
        return False
    return proc.returncode == 0


def configmap_payload(name: str, payload: dict, *, labels: dict | None = None,
                       namespace: str = SYSTEM_NAMESPACE) -> dict:
    """A ConfigMap wrapping one JSON-encoded payload dict under a single
    data key - the plain-data (non-secret) half of this app's CRD-free
    state storage. See this module's docstring."""
    obj = {
        "apiVersion": "v1",
        "kind": "ConfigMap",
        "metadata": {"name": name, "namespace": namespace},
        "data": {_PAYLOAD_KEY: json.dumps(payload)},
    }
    if labels:
        obj["metadata"]["labels"] = dict(labels)
    return obj


def secret_payload(name: str, payload: dict, *, labels: dict | None = None,
                    namespace: str = SYSTEM_NAMESPACE) -> dict:
    """Same shape as configmap_payload, for state that shouldn't sit in
    plain text (currently: password hashes). Written via `stringData` so
    callers never hand-encode base64 - decode_payload transparently
    understands both a locally-built stringData payload (not yet
    round-tripped through the API server) and a real `kubectl get`
    response's base64-encoded `data`."""
    obj = {
        "apiVersion": "v1",
        "kind": "Secret",
        "type": "Opaque",
        "metadata": {"name": name, "namespace": namespace},
        "stringData": {_PAYLOAD_KEY: json.dumps(payload)},
    }
    if labels:
        obj["metadata"]["labels"] = dict(labels)
    return obj


def decode_payload(obj: dict | None) -> dict | None:
    """Reads back a payload written by configmap_payload/secret_payload.
    None if obj is None or carries neither a populated `data` (the
    ConfigMap shape, and what a real `kubectl get` also returns for a
    Secret - base64-encoded there) nor `stringData` (a Secret payload this
    process just built locally and hasn't re-fetched)."""
    if obj is None:
        return None
    raw = (obj.get("data") or {}).get(_PAYLOAD_KEY)
    if raw is not None:
        if obj.get("kind") == "Secret":
            raw = base64.b64decode(raw).decode("utf-8")
        return json.loads(raw)
    raw = (obj.get("stringData") or {}).get(_PAYLOAD_KEY)
    if raw is not None:
        return json.loads(raw)
    return None
