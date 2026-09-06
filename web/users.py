"""Per-user accounts, replacing a single shared password with admin-provisioned
per-user credentials.

Stored as Secrets in kube_json.SYSTEM_NAMESPACE (see kube_json.py's
docstring for why: no domain is confirmed for a project-owned CRD group),
reusing kube_json.py's plain kubectl get/apply helpers rather than
introducing a new database dependency. The user_id is a stable slug derived
from the username at creation time and never recomputed afterward, so it's
safe for per-user namespaces, sessions, profiles,
and terminal tabs to key off it permanently - it's stored in the payload
itself (`userId`) rather than solely relied on as the object's own name, so
a caller never has to reverse-parse it back out of a name prefix.

Accounts are admin-provisioned only - there is no public sign-up route
anywhere in this app (see routers/admin_router.py). Passwords are hashed
with PBKDF2-HMAC-SHA256 (stdlib `hashlib`, no extra dependency): a per-user
random salt plus enough iterations to resist offline brute force if the
user Secrets were ever read directly (`kubectl get secret -o yaml`) - that's
the same trust boundary this app already extends to the operator's own
kubeconfig, not a new one.
"""
from __future__ import annotations

import hashlib
import hmac
import os
import re
import secrets
import threading
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Optional

from kube_json import (
    SYSTEM_NAMESPACE,
    decode_payload,
    kubectl_apply_json,
    kubectl_delete,
    kubectl_get_json,
    secret_payload,
)

_USER_LABELS = {"clusterdrill-kind": "user"}
_USER_LABEL_SELECTOR = "clusterdrill-kind=user"

_PBKDF2_ITERATIONS = 260_000  # OWASP 2023 minimum recommendation for PBKDF2-HMAC-SHA256
_SALT_BYTES = 16
_MIN_PASSWORD_LENGTH = 8
# user_id becomes a Kubernetes namespace
# *suffix* (`qNNN-<user_id>`), and namespace names are capped at 63 chars
# (DNS-1123 label). The longest question id in the bank today is 47 chars -
# capping the slug here at 10 (leaving room for _unique_user_id's own
# "-<n>" collision suffix on top) keeps the worst case at 47 + 1 + 13 = 61,
# with headroom for a future question id to grow a little longer too -
# without ever rejecting a long username outright (friendlier for an admin
# typing a real name/email than a validation error would be).
_MAX_USER_ID_LENGTH = 10

# threading.RLock, not asyncio.Lock: FastAPI's sync `def` routes run in a
# threadpool (Starlette's run_in_threadpool) - same reasoning as
# profile_store.py's own _lock. Reentrant because create_user() calls
# list_users() (which itself takes no lock) while already holding it, and
# ensure_bootstrap_admin() calls create_user() from inside its own
# with-block.
_lock = threading.RLock()


def single_user_mode() -> bool:
    """Whether this deployment permits only its bootstrap administrator.

    The local appliance deliberately runs cluster-scoped CKAD exercises.
    Kubernetes RBAC cannot safely delegate ClusterRoleBinding creation among
    mutually untrusted users, so shared deployments must isolate each learner
    in a separate cluster. The local appliance allows one trusted operator.
    """
    return os.environ.get("CLUSTERDRILL_SINGLE_USER", "").lower() in {"1", "true", "yes"}


class UsernameTakenError(ValueError):
    pass


@dataclass
class User:
    user_id: str
    username: str
    is_admin: bool
    created_at: str


def _slugify(username: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", username.lower()).strip("-")
    slug = slug[:_MAX_USER_ID_LENGTH].rstrip("-")
    return slug or "user"


def _hash_digest(password: str, salt: bytes) -> str:
    return hashlib.pbkdf2_hmac(
        "sha256", password.encode("utf-8"), salt, _PBKDF2_ITERATIONS
    ).hex()


def _new_password_record(password: str) -> str:
    salt = secrets.token_bytes(_SALT_BYTES)
    return f"{salt.hex()}${_hash_digest(password, salt)}"


def _verify_password(password: str, stored: str) -> bool:
    try:
        salt_hex, digest_hex = stored.split("$", 1)
        salt = bytes.fromhex(salt_hex)
    except ValueError:
        return False
    candidate_digest = _hash_digest(password, salt)
    return hmac.compare_digest(candidate_digest, digest_hex)


def _require_valid_password(password: str) -> None:
    if len(password) < _MIN_PASSWORD_LENGTH:
        raise ValueError(f"password must be at least {_MIN_PASSWORD_LENGTH} characters")


def _user_object_name(user_id: str) -> str:
    return f"clusterdrill-user-{user_id}"


def _to_user(obj: dict) -> User:
    spec = decode_payload(obj) or {}
    return User(
        user_id=spec.get("userId", ""),
        username=spec.get("username", ""),
        is_admin=bool(spec.get("isAdmin", False)),
        created_at=spec.get("createdAt", ""),
    )


def list_users() -> list[User]:
    obj = kubectl_get_json("secret", "-n", SYSTEM_NAMESPACE, "-l", _USER_LABEL_SELECTOR)
    if obj is None:
        return []
    return [_to_user(item) for item in obj.get("items", [])]


def get_user(user_id: str) -> Optional[User]:
    obj = kubectl_get_json("secret", _user_object_name(user_id), "-n", SYSTEM_NAMESPACE)
    return _to_user(obj) if obj is not None else None


def get_user_by_username(username: str) -> Optional[User]:
    target = username.strip().lower()
    for user in list_users():
        if user.username.lower() == target:
            return user
    return None


def _unique_user_id(username: str) -> str:
    """Appends -2, -3, ... on a slug collision (e.g. "Alex" and "alex!" both
    slugify to "alex") - two people's chosen usernames colliding on the slug
    is a real possibility this small a namespace shouldn't just fail on, and
    username uniqueness (checked in create_user) is what actually matters
    for login, not the id."""
    base = _slugify(username)
    existing_ids = {u.user_id for u in list_users()}
    if base not in existing_ids:
        return base
    suffix = 2
    while f"{base}-{suffix}" in existing_ids:
        suffix += 1
    return f"{base}-{suffix}"


def create_user(username: str, password: str, is_admin: bool = False) -> User:
    username = username.strip()
    if not username:
        raise ValueError("username must not be empty")
    _require_valid_password(password)
    with _lock:
        existing_users = list_users()
        if single_user_mode() and not (
            username == "admin" and is_admin and not existing_users
        ):
            raise ValueError(
                "This local appliance is single-user. "
                "Use an isolated cluster per learner for shared access."
            )
        if any(user.username.lower() == username.lower() for user in existing_users):
            raise UsernameTakenError(f"username {username!r} is already taken")
        user_id = _unique_user_id(username)
        spec = {
            "userId": user_id,
            "username": username,
            "passwordHash": _new_password_record(password),
            "isAdmin": is_admin,
            "createdAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        }
        obj = secret_payload(_user_object_name(user_id), spec, labels=_USER_LABELS)
        kubectl_apply_json(obj)
        return _to_user(obj)


def set_password(user_id: str, password: str) -> bool:
    """Returns False if user_id doesn't exist, so callers (the admin route)
    can tell "no such user" apart from a validation error."""
    _require_valid_password(password)
    with _lock:
        obj = kubectl_get_json("secret", _user_object_name(user_id), "-n", SYSTEM_NAMESPACE)
        if obj is None:
            return False
        spec = decode_payload(obj) or {}
        spec["passwordHash"] = _new_password_record(password)
        new_obj = secret_payload(_user_object_name(user_id), spec, labels=_USER_LABELS)
        return kubectl_apply_json(new_obj)


def delete_user(user_id: str) -> bool:
    return kubectl_delete("secret", _user_object_name(user_id), "-n", SYSTEM_NAMESPACE)


# Fixed at import time so every "no such user" path burns the same PBKDF2
# cost as a real lookup would - closes the username-enumeration-via-timing
# gap flagged in issue #25's review: an unknown username used to return
# immediately, skipping _hash_digest entirely, while a known username with
# a wrong password paid the full 260k-iteration cost. Random password so
# the record itself can never be a valid credential for any real account.
_DUMMY_PASSWORD_RECORD = _new_password_record(secrets.token_urlsafe(32))


def authenticate(username: str, password: str) -> Optional[User]:
    """Returns the matching User on a correct username+password, else None.
    Constant-time digest comparison (_verify_password) so a wrong guess
    doesn't leak timing info about how many leading bytes of the hash it
    got right. Every rejection path also runs one _verify_password call
    against _DUMMY_PASSWORD_RECORD before returning, so an unknown username,
    a single-user-mode rejection, and a wrong password are all
    indistinguishable by response time.
    """
    user = get_user_by_username(username)
    if user is None:
        _verify_password(password, _DUMMY_PASSWORD_RECORD)
        return None
    if single_user_mode() and user.user_id != "admin":
        _verify_password(password, _DUMMY_PASSWORD_RECORD)
        return None
    obj = kubectl_get_json("secret", _user_object_name(user.user_id), "-n", SYSTEM_NAMESPACE)
    spec = decode_payload(obj) or {}
    stored_hash = spec.get("passwordHash")
    if not stored_hash:
        _verify_password(password, _DUMMY_PASSWORD_RECORD)
        return None
    if not _verify_password(password, stored_hash):
        return None
    return user


def ensure_bootstrap_admin() -> None:
    """Idempotent, called once on every app startup (app.py's lifespan,
    after rbac.ensure_system_bootstrap has created SYSTEM_NAMESPACE): if
    there are zero accounts yet and CLUSTERDRILL_PASSWORD is set, creates one
    admin account named "admin" using that same password. This is what
    lets an existing single-shared-password deployment
    upgrade to accounts without losing access to its own app - the
    operator's existing env var becomes their first login instead of a
    stranded, no-longer-checked setting. A no-op on every later boot once
    at least one account exists; CLUSTERDRILL_PASSWORD is never consulted
    for authentication itself after this, only as this one-time seed
    (auth.password_gate_enabled() still reads it separately, as the
    on/off switch for requiring login at all).
    """
    seed_password = os.environ.get("CLUSTERDRILL_PASSWORD")
    if not seed_password:
        return
    with _lock:
        if list_users():
            return
        create_user("admin", seed_password, is_admin=True)
