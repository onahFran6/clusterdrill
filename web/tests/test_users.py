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


class FakeCluster:
    """In-memory stand-in for `kubectl get/apply/delete secret` - a dict
    keyed by the Secret's object name, matching kube_json's JSON shape
    closely enough for users.py's own parsing (_to_user) to work
    unmodified against it."""

    def __init__(self):
        self.objects: dict[str, dict] = {}

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
        self.objects[obj["metadata"]["name"]] = obj
        return True

    def delete(self, *args: str) -> bool:
        self.objects.pop(args[1], None)
        return True


@pytest.fixture
def cluster(monkeypatch):
    fake = FakeCluster()
    monkeypatch.setattr(users, "kubectl_get_json", fake.get_json)
    monkeypatch.setattr(users, "kubectl_apply_json", fake.apply_json)
    monkeypatch.setattr(users, "kubectl_delete", fake.delete)
    return fake


# --- create_user / list_users / get_user ------------------------------------

def test_create_user_round_trips(cluster):
    user = users.create_user("Alice", "hunter22222", is_admin=True)
    assert user.username == "Alice"
    assert user.is_admin is True
    assert user.user_id == "alice"

    fetched = users.get_user("alice")
    assert fetched == user


def test_create_user_slugifies_username_for_id(cluster):
    user = users.create_user("Bob Smith!", "hunter22222")
    assert user.user_id == "bob-smith"


def test_create_user_rejects_duplicate_username(cluster):
    users.create_user("alice", "hunter22222")
    with pytest.raises(users.UsernameTakenError):
        users.create_user("alice", "different-pass")


def test_create_user_username_match_is_case_insensitive(cluster):
    users.create_user("Alice", "hunter22222")
    with pytest.raises(users.UsernameTakenError):
        users.create_user("ALICE", "different-pass")


def test_create_user_rejects_short_password(cluster):
    with pytest.raises(ValueError):
        users.create_user("alice", "short")


def test_create_user_rejects_empty_username(cluster):
    with pytest.raises(ValueError):
        users.create_user("   ", "hunter22222")


def test_unique_user_id_appends_suffix_on_slug_collision(cluster):
    first = users.create_user("Alex", "hunter22222")
    second = users.create_user("alex!", "hunter22222")
    assert first.user_id == "alex"
    assert second.user_id == "alex-2"


def test_list_users_empty_initially(cluster):
    assert users.list_users() == []


def test_get_user_by_username_case_insensitive(cluster):
    users.create_user("Alice", "hunter22222")
    assert users.get_user_by_username("ALICE") is not None
    assert users.get_user_by_username("bob") is None


def test_get_user_missing_returns_none(cluster):
    assert users.get_user("nope") is None


# --- authenticate ------------------------------------------------------------

def test_authenticate_correct_password(cluster):
    users.create_user("alice", "hunter22222")
    user = users.authenticate("alice", "hunter22222")
    assert user is not None
    assert user.username == "alice"


def test_authenticate_wrong_password(cluster):
    users.create_user("alice", "hunter22222")
    assert users.authenticate("alice", "wrong-password") is None


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


def test_single_user_mode_allows_only_bootstrap_admin(cluster, monkeypatch):
    monkeypatch.setenv("CLUSTERDRILL_SINGLE_USER", "true")
    admin = users.create_user("admin", "hunter22222", is_admin=True)
    assert admin.user_id == "admin"
    assert users.authenticate("admin", "hunter22222") == admin
    with pytest.raises(ValueError, match="single-user"):
        users.create_user("alice", "hunter22222")


def test_single_user_mode_rejects_existing_non_admin_login(cluster, monkeypatch):
    users.create_user("alice", "hunter22222")
    monkeypatch.setenv("CLUSTERDRILL_SINGLE_USER", "true")
    assert users.authenticate("alice", "hunter22222") is None


def test_password_hash_never_stored_in_plaintext(cluster):
    from kube_json import decode_payload

    users.create_user("alice", "hunter22222")
    obj = cluster.objects[users._user_object_name("alice")]
    spec = decode_payload(obj)
    assert "hunter22222" not in spec["passwordHash"]


# --- set_password / delete_user ----------------------------------------------

def test_set_password_changes_login(cluster):
    users.create_user("alice", "old-password")
    assert users.set_password("alice", "new-password-2") is True
    assert users.authenticate("alice", "old-password") is None
    assert users.authenticate("alice", "new-password-2") is not None


def test_set_password_missing_user_returns_false(cluster):
    assert users.set_password("nope", "new-password-2") is False


def test_set_password_rejects_short_password(cluster):
    users.create_user("alice", "old-password")
    with pytest.raises(ValueError):
        users.set_password("alice", "short")


def test_delete_user_removes_account(cluster):
    users.create_user("alice", "hunter22222")
    assert users.delete_user("alice") is True
    assert users.get_user("alice") is None
    assert users.authenticate("alice", "hunter22222") is None


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
    users.create_user("someone-else", "hunter22222")
    users.ensure_bootstrap_admin()
    assert users.get_user_by_username("admin") is None
