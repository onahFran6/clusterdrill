"""users.py: per-user accounts. Mocks kube_json's
kubectl_get_json/kubectl_apply_json/kubectl_delete directly with an
in-memory fake store, rather than going through real subprocess calls
(which conftest.py's autouse guard forbids anyway) - this exercises
users.py's own logic (slugging, hashing, uniqueness, bootstrap) against a
fake cluster, not kubectl's wire format.
"""
from __future__ import annotations

import pytest
import users
from kube_json import StorageWriteError


class FakeCluster:
    """In-memory stand-in for `kubectl get/apply/delete secret` - a dict
    keyed by the Secret's object name, matching kube_json's JSON shape
    closely enough for users.py's own parsing (_to_user) to work
    unmodified against it."""

    def __init__(self):
        self.objects: dict[str, dict] = {}
        self.fail_next_apply = False

    def get_json(self, *args: str):
        # A single-object get looks like ("secret", name, "-n", ns); a list
        # call looks like ("secret", "-n", ns, "-l", selector).
        if len(args) >= 2 and not str(args[1]).startswith("-"):
            return self.objects.get(args[1])
        selector = None
        if "-l" in args:
            selector = args[args.index("-l") + 1]
        items = list(self.objects.values())
        if selector:
            key, _, val = selector.partition("=")
            items = [v for v in items if v.get("metadata", {}).get("labels", {}).get(key) == val]
        return {"items": items}

    def apply_json(self, obj: dict) -> bool:
        if self.fail_next_apply:
            self.fail_next_apply = False
            return False
        self.objects[obj["metadata"]["name"]] = obj
        return True

    def apply_json_or_raise(self, obj: dict, *, what: str) -> None:
        if not self.apply_json(obj):
            raise StorageWriteError(f"failed to persist {what}")

    def delete(self, *args: str) -> bool:
        self.objects.pop(args[1], None)
        return True


@pytest.fixture
def cluster(monkeypatch):
    fake = FakeCluster()
    monkeypatch.setattr(users, "kubectl_get_json", fake.get_json)
    monkeypatch.setattr(users, "kubectl_apply_json", fake.apply_json)
    monkeypatch.setattr(users, "kubectl_apply_json_or_raise", fake.apply_json_or_raise)
    monkeypatch.setattr(users, "kubectl_delete", fake.delete)
    return fake


# --- create_user / list_users / get_user ------------------------------------
#
# Proposal A (C01/C02): single_user_mode() is now always True, so the only
# account create_user() will ever let through is the one bootstrap
# "admin" call - a second, differently-named account is a removed
# capability, not just a disabled default. Tests below that need an
# "already exists" account beyond that one bootstrap call seed it directly
# into the fake cluster (bypassing create_user's own gate) rather than
# pretending that capability still exists.

def _seed_existing_account(cluster, user_id: str, username: str, *, is_admin: bool = False) -> None:
    from kube_json import secret_payload

    spec = {
        "userId": user_id, "username": username,
        "passwordHash": users._new_password_record("whatever-was-set-before"),
        "isAdmin": is_admin, "createdAt": "2026-01-01T00:00:00Z",
    }
    obj = secret_payload(users._user_object_name(user_id), spec, labels=users._USER_LABELS)
    cluster.apply_json(obj)


def test_create_user_round_trips(cluster):
    user = users.create_user("admin", "hunter22222", is_admin=True)
    assert user.username == "admin"
    assert user.is_admin is True
    assert user.user_id == "admin"

    fetched = users.get_user("admin")
    assert fetched == user


def test_slugify_lowercases_and_replaces_non_alnum():
    # _slugify itself is still real, used code (it's what turns "admin"
    # into the "admin" user_id too) - exercised directly since create_user
    # can no longer be used to feed it an arbitrary username.
    assert users._slugify("Bob Smith!") == "bob-smith"
    assert users._slugify("  ") == "user"


def test_create_user_rejects_a_second_account(cluster):
    users.create_user("admin", "hunter22222", is_admin=True)
    with pytest.raises(ValueError, match="single-user"):
        users.create_user("alice", "different-pass")


def test_create_user_rejects_short_password(cluster):
    with pytest.raises(ValueError):
        users.create_user("alice", "short")


def test_create_user_rejects_empty_username(cluster):
    with pytest.raises(ValueError):
        users.create_user("   ", "hunter22222")


def test_unique_user_id_appends_suffix_on_slug_collision(cluster):
    # _unique_user_id's "-2" suffix branch can no longer be reached through
    # create_user (there's never a second account to collide with) - still
    # real logic, so seed a colliding "existing" account directly and
    # exercise the function on its own.
    _seed_existing_account(cluster, "alex", "Alex")
    assert users._unique_user_id("alex!") == "alex-2"


def test_list_users_empty_initially(cluster):
    assert users.list_users() == []


def test_get_user_by_username_case_insensitive(cluster):
    users.create_user("admin", "hunter22222", is_admin=True)
    assert users.get_user_by_username("ADMIN") is not None
    assert users.get_user_by_username("bob") is None


def test_get_user_missing_returns_none(cluster):
    assert users.get_user("nope") is None


# --- authenticate ------------------------------------------------------------

def test_authenticate_correct_password(cluster):
    users.create_user("admin", "hunter22222", is_admin=True)
    user = users.authenticate("admin", "hunter22222")
    assert user is not None
    assert user.username == "admin"


def test_authenticate_wrong_password(cluster):
    users.create_user("admin", "hunter22222", is_admin=True)
    assert users.authenticate("admin", "wrong-password") is None


def test_authenticate_unknown_username(cluster):
    assert users.authenticate("nobody", "hunter22222") is None


def test_authenticate_unknown_username_still_hashes(cluster, monkeypatch):
    # Regression for issue #25's review: an unknown username used to return
    # before ever calling _verify_password, making it distinguishable by
    # timing from a known username with a wrong password. Assert the dummy
    # comparison actually runs rather than just trusting the None result.
    calls = []
    real_verify = users._verify_password
    monkeypatch.setattr(
        users, "_verify_password",
        lambda password, stored: calls.append(stored) or real_verify(password, stored),
    )
    assert users.authenticate("nobody", "hunter22222") is None
    assert calls == [users._DUMMY_PASSWORD_RECORD]


def test_authenticate_rejects_a_non_admin_account_even_if_one_already_exists(cluster):
    # A pre-existing non-admin account (e.g. from before this single-user
    # policy was enforced) must not be able to log in at all - single-user
    # mode isn't just "can't create new non-admin accounts", it's "only the
    # admin account is a valid identity", covering an upgrade from an older
    # deployment that still has one lying around.
    _seed_existing_account(cluster, "alice", "alice")
    assert users.authenticate("alice", "whatever-was-set-before") is None


def test_password_hash_never_stored_in_plaintext(cluster):
    from kube_json import decode_payload

    users.create_user("admin", "hunter22222", is_admin=True)
    obj = cluster.objects[users._user_object_name("admin")]
    spec = decode_payload(obj)
    assert "hunter22222" not in spec["passwordHash"]


# --- set_password / delete_user ----------------------------------------------

def test_set_password_changes_login(cluster):
    users.create_user("admin", "old-password", is_admin=True)
    assert users.set_password("admin", "new-password-2") is True
    assert users.authenticate("admin", "old-password") is None
    assert users.authenticate("admin", "new-password-2") is not None


def test_set_password_missing_user_returns_false(cluster):
    assert users.set_password("nope", "new-password-2") is False


def test_set_password_rejects_short_password(cluster):
    users.create_user("admin", "old-password", is_admin=True)
    with pytest.raises(ValueError):
        users.set_password("admin", "short")


def test_delete_user_removes_account(cluster):
    users.create_user("admin", "hunter22222", is_admin=True)
    assert users.delete_user("admin") is True
    assert users.get_user("admin") is None
    assert users.authenticate("admin", "hunter22222") is None


# --- ensure_bootstrap_admin ---------------------------------------------------

def test_ensure_bootstrap_admin_creates_admin_from_env(cluster, monkeypatch):
    monkeypatch.setenv("CLUSTERDRILL_PASSWORD", "legacy-shared-password")
    users.ensure_bootstrap_admin()
    admin = users.get_user_by_username("admin")
    assert admin is not None
    assert admin.is_admin is True
    assert users.authenticate("admin", "legacy-shared-password") is not None


def test_ensure_bootstrap_admin_noop_without_env(cluster, monkeypatch):
    monkeypatch.delenv("CLUSTERDRILL_PASSWORD", raising=False)
    users.ensure_bootstrap_admin()
    assert users.list_users() == []


def test_ensure_bootstrap_admin_noop_if_users_already_exist(cluster, monkeypatch):
    monkeypatch.setenv("CLUSTERDRILL_PASSWORD", "legacy-shared-password")
    _seed_existing_account(cluster, "admin", "admin", is_admin=True)
    users.ensure_bootstrap_admin()
    # Still the one pre-existing account, untouched - not re-seeded/reset.
    assert users.authenticate("admin", "legacy-shared-password") is None
