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
import logging
import subprocess
from dataclasses import dataclass

logger = logging.getLogger("clusterdrill.kube_json")

KUBECTL_TIMEOUT_SECONDS = 15
SYSTEM_NAMESPACE = "clusterdrill-system"
_PAYLOAD_KEY = "data.json"
_LOGGED_STDERR_CHARS = 500  # bounded (I05): never flood logs with a huge kubectl error dump


class StorageWriteError(RuntimeError):
    """A kubectl apply that was supposed to persist app state (profile,
    achievement, account) did not actually succeed. Callers must not build
    a success-shaped return value (a Profile/User object) from data that was
    never durably written - see R09 in the security audit: a caller that
    discards kubectl_apply_json's bool return can show "saved" for progress
    that silently never reached the cluster."""


class StorageReadError(RuntimeError):
    """A kubectl read failed (timeout, Forbidden, API server unreachable) in
    a way that must not be treated as "the object doesn't exist yet" - doing
    so has previously caused a transient API hiccup to look identical to a
    fresh account/profile and triggered create-on-first-use logic against
    data that was there all along."""


def kubectl_get_json(*args: str) -> dict | None:
    try:
        proc = subprocess.run(
            ["kubectl", "get", *args, "-o", "json"],
            capture_output=True, text=True, timeout=KUBECTL_TIMEOUT_SECONDS,
        )
    except subprocess.TimeoutExpired:
        logger.warning("kubectl get %s timed out after %ss", args, KUBECTL_TIMEOUT_SECONDS)
        return None
    except OSError as exc:
        logger.warning("kubectl get %s failed to run: %s", args, exc)
        return None
    if proc.returncode != 0:
        # Bounded, not discarded (I05): this function's return type can't
        # distinguish "confirmed absent" from "the read itself failed" for
        # its own callers (see StorageReadError's docstring/kubectl_get_
        # json_safe for the typed alternative) - logging what kubectl
        # actually said is the only diagnostic trail left for an operator
        # when a caller's "not found" turns out to have really been a
        # transient API/RBAC failure.
        logger.warning(
            "kubectl get %s exited %s: %s", args, proc.returncode, proc.stderr.strip()[:_LOGGED_STDERR_CHARS],
        )
        return None
    try:
        return json.loads(proc.stdout)
    except json.JSONDecodeError:
        logger.warning("kubectl get %s returned malformed JSON", args)
        return None


@dataclass
class KubectlGetResult:
    """`data` is the decoded object, or None if the lookup confirmed it
    doesn't exist. `error` is non-None only when the read itself failed
    (timeout/Forbidden/malformed output/etc) - in that case `data` carries
    no meaning and must never be read as "not found"."""
    data: dict | None
    error: str | None = None

    @property
    def ok(self) -> bool:
        return self.error is None


def kubectl_get_json_safe(*args: str) -> KubectlGetResult:
    """Like kubectl_get_json, but for a single named object lookup where the
    caller needs to tell "confirmed absent" apart from "failed to read" (see
    StorageReadError). Passes --ignore-not-found so a missing object comes
    back as returncode 0 with empty stdout, not a nonzero exit indistinguishable
    from every other kubectl failure; not meaningful for list/selector
    queries, which already return an empty `items` array without erroring."""
    try:
        proc = subprocess.run(
            ["kubectl", "get", *args, "--ignore-not-found", "-o", "json"],
            capture_output=True, text=True, timeout=KUBECTL_TIMEOUT_SECONDS,
        )
    except subprocess.TimeoutExpired:
        return KubectlGetResult(data=None, error="kubectl get timed out")
    except OSError as exc:
        return KubectlGetResult(data=None, error=f"failed to run kubectl get: {exc}")
    if proc.returncode != 0:
        return KubectlGetResult(data=None, error=proc.stderr.strip() or f"kubectl get exited {proc.returncode}")
    if not proc.stdout.strip():
        return KubectlGetResult(data=None)  # confirmed absent
    try:
        return KubectlGetResult(data=json.loads(proc.stdout))
    except json.JSONDecodeError as exc:
        return KubectlGetResult(data=None, error=f"malformed kubectl output: {exc}")


def kubectl_apply_json(obj: dict) -> bool:
    try:
        proc = subprocess.run(
            ["kubectl", "apply", "-f", "-"],
            input=json.dumps(obj),
            capture_output=True, text=True, timeout=KUBECTL_TIMEOUT_SECONDS,
        )
    except subprocess.TimeoutExpired:
        logger.warning(
            "kubectl apply timed out after %ss (kind=%s name=%s)",
            KUBECTL_TIMEOUT_SECONDS, obj.get("kind"), (obj.get("metadata") or {}).get("name"),
        )
        return False
    except OSError as exc:
        logger.warning("kubectl apply failed to run: %s", exc)
        return False
    if proc.returncode != 0:
        # Bounded, not discarded (I05) - same reasoning as kubectl_get_json
        # above. kubectl_apply_json_or_raise's StorageWriteError already
        # surfaces this to the caller for the write paths that need it;
        # this is the last diagnostic trail for the ones that don't.
        logger.warning(
            "kubectl apply exited %s (kind=%s name=%s): %s",
            proc.returncode, obj.get("kind"), (obj.get("metadata") or {}).get("name"),
            proc.stderr.strip()[:_LOGGED_STDERR_CHARS],
        )
    return proc.returncode == 0


def kubectl_apply_json_or_raise(obj: dict, *, what: str) -> None:
    """Same apply as kubectl_apply_json, but raises StorageWriteError instead
    of returning False - for the write paths where a caller would otherwise
    hand back a success-shaped result built from data that was never
    actually persisted (profile saves, achievement unlocks, account
    creation)."""
    if not kubectl_apply_json(obj):
        raise StorageWriteError(f"failed to persist {what}")


def kubectl_delete(*args: str) -> bool:
    try:
        proc = subprocess.run(
            ["kubectl", "delete", *args, "--ignore-not-found=true"],
            capture_output=True, text=True, timeout=KUBECTL_TIMEOUT_SECONDS,
        )
    except subprocess.TimeoutExpired:
        logger.warning("kubectl delete %s timed out after %ss", args, KUBECTL_TIMEOUT_SECONDS)
        return False
    except OSError as exc:
        logger.warning("kubectl delete %s failed to run: %s", args, exc)
        return False
    if proc.returncode != 0:
        logger.warning(
            "kubectl delete %s exited %s: %s", args, proc.returncode, proc.stderr.strip()[:_LOGGED_STDERR_CHARS],
        )
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
