"""Route-level tests for routers/admin_router.py.

Proposal A (C01/C02): users.single_user_mode() is now always True, so
GET /admin always 404s and POST /admin/users always 403s, unconditionally -
the multi-account admin UI is a removed capability, not a disabled
default. These tests cover the two POST routes that remain genuinely
reachable (reset-password, delete), the guardrails on delete (self-delete,
last-admin), and that create/the page itself are now permanently dead.
Any "second account" these tests need (to test delete's cascade teardown,
or the last-admin guardrail with an actual other admin present) is seeded
directly into the fake cluster via _seed_user, not through
users.create_user() - that function enforces the same one-account policy
now, so it can no longer produce one.

Most tests run with the password gate off (no CLUSTERDRILL_PASSWORD), same
as the rest of tests/routes/ - auth.require_admin and
auth.csrf_protect_form both no-op in that mode. A separate section covers
the require_admin authorization boundary itself with the gate on.

users.py's kubectl calls are faked the same way tests/test_users.py does -
an in-memory dict standing in for `kubectl get/apply/delete secret`.

Delete-user also schedules grading_client.run_batch_cleanup as a FastAPI
BackgroundTask (the namespace-cascade fix for issue #25/PLAN.md §4.12) -
same "never leave it unmocked" concern as tests/routes/test_sessions_
routes.py's module docstring explains in full: background tasks run
synchronously under httpx.ASGITransport, and the real call would shell out
to lib/grading.sh -> real kubectl, which the subprocess safety net can't
see inside a spawned `bash -c '...'`. The `cluster` fixture mocks it (and
profile_store's own kubectl calls) for every test that uses it.
"""
from __future__ import annotations

import profile_store
import pytest
import routers.admin_router as admin_router
import users
from kube_json import KubectlGetResult, StorageWriteError, decode_payload


class FakeCluster:
    def __init__(self):
        self.objects: dict[str, dict] = {}

    def get_json(self, *args: str):
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

    def get_json_safe(self, *args: str) -> KubectlGetResult:
        return KubectlGetResult(data=self.get_json(*args))

    def apply_json(self, obj: dict) -> bool:
        self.objects[obj["metadata"]["name"]] = obj
        return True

    def apply_json_or_raise(self, obj: dict, *, what: str) -> None:
        if not self.apply_json(obj):
            raise StorageWriteError(f"failed to persist {what}")

    def delete(self, *args: str) -> bool:
        if len(args) >= 2 and not str(args[1]).startswith("-"):
            self.objects.pop(args[1], None)
            return True
        # Label-selector delete (profile_store.delete_profile's achievement
        # cleanup) - same selector parsing as get_json above.
        if "-l" in args:
            key, _, val = args[args.index("-l") + 1].partition("=")
            for name in [
                n for n, obj in self.objects.items()
                if obj.get("metadata", {}).get("labels", {}).get(key) == val
            ]:
                self.objects.pop(name, None)
        return True


def _seed_user(fake: FakeCluster, user_id: str, username: str, *, is_admin: bool = False) -> None:
    """Directly injects an account Secret into the fake cluster, bypassing
    users.create_user() - which, now that single_user_mode() is always
    True, will only ever let the one bootstrap "admin" account through.
    Everything these tests need beyond that (a second admin for the
    last-admin guardrail, an "alice" to delete and verify cascade teardown
    against) models an account that's already there, not one created
    through the (removed) multi-account creation capability."""
    from kube_json import secret_payload

    spec = {
        "userId": user_id, "username": username,
        "passwordHash": users._new_password_record("irrelevant-authenticate-is-mocked"),
        "isAdmin": is_admin, "createdAt": "2026-01-01T00:00:00Z",
    }
    fake.apply_json(secret_payload(users._user_object_name(user_id), spec, labels=users._USER_LABELS))


@pytest.fixture
def cluster(monkeypatch):
    """Backs users.py's account storage with an in-memory fake, and makes
    users.get_user() read from that same fake regardless of fixture setup
    order against tests/routes/conftest.py's autouse fake_user_store (which
    also stubs users.get_user for its own fixed TEST_USER) - see this
    fixture's re-patch of get_user below."""
    fake = FakeCluster()
    monkeypatch.setattr(users, "kubectl_get_json", fake.get_json)
    monkeypatch.setattr(users, "kubectl_apply_json", fake.apply_json)
    monkeypatch.setattr(users, "kubectl_apply_json_or_raise", fake.apply_json_or_raise)
    monkeypatch.setattr(users, "kubectl_delete", fake.delete)
    monkeypatch.setattr(profile_store, "kubectl_get_json_safe", fake.get_json_safe)
    monkeypatch.setattr(profile_store, "kubectl_apply_json_or_raise", fake.apply_json_or_raise)
    monkeypatch.setattr(profile_store, "kubectl_delete", fake.delete)
    monkeypatch.setattr(admin_router, "run_batch_cleanup", lambda *a, **k: None)

    def real_get_user(user_id: str):
        obj = fake.get_json("secret", users._user_object_name(user_id), "-n", users.SYSTEM_NAMESPACE)
        return users._to_user(obj) if obj is not None else None

    monkeypatch.setattr(users, "get_user", real_get_user)
    # Matches conftest.py's fake_user_store TEST_USER (user_id "tester",
    # is_admin=True) so logging in as "tester" resolves to a real admin
    # record here, not a 404 from require_admin's live get_user() lookup.
    _seed_user(fake, "tester", "tester", is_admin=True)
    return fake


def _csrf_form(csrf_token="anything-when-gate-off", **fields):
    return {"csrf_token": csrf_token, **fields}


# --- GET /admin and POST /admin/users: permanently dead now (Proposal A) ---
# users.single_user_mode() is always True, so these never do anything else,
# regardless of login/gate state or input - both routes check it before
# anything else.

async def test_admin_page_always_404s(client, cluster):
    res = await client.get("/admin")
    assert res.status_code == 404


async def test_create_user_always_403s_regardless_of_input(client, cluster):
    res = await client.post(
        "/admin/users", data=_csrf_form(username="alice", password="hunter22222"), follow_redirects=False,
    )
    assert res.status_code == 403
    assert users.get_user_by_username("alice") is None


# --- reset-password / delete: still genuinely reachable (no top-of-route
# single_user_mode() gate), just no longer discoverable via any UI link
# since the page itself 404s. Still real, live-reachable code. ---------------

async def test_reset_password_changes_login(client, cluster):
    # Resets the one existing ("tester") account's own password - the only
    # account reset-password can ever target now. Checks the stored hash
    # directly rather than via users.authenticate() - conftest.py's
    # autouse fake_user_store fixture stubs authenticate() wholesale for
    # its own fixed "tester" account, so it can't tell the old password
    # apart from the new one here.
    res = await client.post(
        "/admin/users/tester/reset-password",
        data=_csrf_form(password="new-password-2"),
        follow_redirects=False,
    )
    assert res.status_code == 303
    stored = decode_payload(cluster.objects[users._user_object_name("tester")])
    stored_hash = stored["passwordHash"]
    assert users._verify_password("new-password-2", stored_hash) is True


async def test_reset_password_missing_user_404(client, cluster):
    res = await client.post("/admin/users/no-such-id/reset-password", data=_csrf_form(password="new-password-2"))
    assert res.status_code == 404


async def test_reset_password_redirects_with_success_code(client, cluster):
    res = await client.post(
        "/admin/users/tester/reset-password", data=_csrf_form(password="new-password-2"), follow_redirects=False,
    )
    assert res.headers["location"] == "/admin?success=reset"


async def test_delete_user_cannot_delete_self(client, cluster, monkeypatch):
    # Simulate being logged in as "tester" without a real login round-trip -
    # directly stub what admin_router reads via auth.current_user_id.
    import auth

    monkeypatch.setattr(auth, "current_user_id", lambda session: "tester")
    res = await client.post("/admin/users/tester/delete", data=_csrf_form())
    assert res.status_code == 400
    assert users.get_user("tester") is not None


async def test_delete_user_cannot_delete_last_admin(client, cluster, monkeypatch):
    import auth

    monkeypatch.setattr(auth, "current_user_id", lambda session: None)
    res = await client.post("/admin/users/tester/delete", data=_csrf_form())
    assert res.status_code == 400
    assert users.get_user("tester") is not None


async def test_delete_user_allowed_when_another_admin_remains(client, cluster, monkeypatch):
    # The one way a second account can exist at all now: seeded directly,
    # not created through the (removed) admin UI - modeling an account
    # left over from before this policy, or an operator editing the
    # Secret by hand. The last-admin guardrail logic itself doesn't care
    # how "otheradmin" came to exist.
    import auth

    _seed_user(cluster, "otheradmin", "otheradmin", is_admin=True)
    monkeypatch.setattr(auth, "current_user_id", lambda session: "otheradmin")
    res = await client.post("/admin/users/tester/delete", data=_csrf_form(), follow_redirects=False)
    assert res.status_code == 303
    assert users.get_user("tester") is None


# --- delete-user cascade teardown (issue #25 / PLAN.md §4.12) ---------------
# The account-removal mechanics above (self-delete/last-admin guardrails,
# auth/tmux/RBAC teardown) predate this section - these specifically cover
# the namespace/session/profile cascade that PLAN.md §4.12 requires but
# admin_router previously never implemented: a deleted account left its
# entire practice-session footprint (namespaces, active session, profile/
# achievement state) running with no owner. "alice"/"bob" here are seeded
# directly (not via users.create_user(), a removed capability under
# Proposal A) - modeling accounts that already existed, independent of how.

async def test_delete_user_schedules_namespace_cleanup_for_every_bank_question(client, cluster, monkeypatch):
    from unittest.mock import MagicMock

    from grading_client import ResetResult

    from questions import bank

    mock_cleanup = MagicMock(return_value=ResetResult(ok=True, output=""))
    monkeypatch.setattr(admin_router, "run_batch_cleanup", mock_cleanup)
    _seed_user(cluster, "alice", "alice")

    res = await client.post("/admin/users/alice/delete", data=_csrf_form(), follow_redirects=False)

    assert res.status_code == 303
    mock_cleanup.assert_called_once()
    call_args = mock_cleanup.call_args.args
    assert call_args[0] == [q.id for q in bank.questions]
    assert call_args[2] == "alice"


async def test_delete_user_clears_active_session(client, cluster, monkeypatch):
    from sessions import ActiveSession
    from sessions import store as session_store

    _seed_user(cluster, "alice", "alice")
    session_store.set_active(ActiveSession(question_ids=["q1"], mode="fixed", topic="topic-a"), "alice")
    assert session_store.get("alice") is not None

    res = await client.post("/admin/users/alice/delete", data=_csrf_form(), follow_redirects=False)

    assert res.status_code == 303
    assert session_store.get("alice") is None


async def test_delete_user_clears_auto_provision_cache_for_that_user_only(client, cluster):
    from services import question_view

    _seed_user(cluster, "alice", "alice")
    _seed_user(cluster, "bob", "bob")
    question_view._auto_provisioned_qids.add(("q101-01-example", "alice"))
    question_view._auto_provisioned_qids.add(("q101-01-example", "bob"))

    res = await client.post("/admin/users/alice/delete", data=_csrf_form(), follow_redirects=False)

    assert res.status_code == 303
    assert ("q101-01-example", "alice") not in question_view._auto_provisioned_qids
    assert ("q101-01-example", "bob") in question_view._auto_provisioned_qids
    question_view._auto_provisioned_qids.clear()


async def test_delete_user_removes_profile_and_achievement_state(client, cluster):
    _seed_user(cluster, "alice", "alice")
    alice_id = "alice"
    # conftest.py's autouse fake_profile fixture stubs profile_store.
    # get_profile() outright (a fixed empty Profile, never touching
    # kubectl) for every route test - seed the profile ConfigMap directly
    # via _save_profile instead, which that fixture does not touch.
    profile_store._save_profile(dict(profile_store._EMPTY_PROFILE_SPEC), alice_id)
    profile_store.apply_achievement("no-hints-q101-01", "no_hints", user_id=alice_id)
    assert profile_store._profile_object_name(alice_id) in cluster.objects
    achievement_name = profile_store._achievement_object_name(
        profile_store._scoped("no-hints-q101-01", alice_id)
    )
    assert achievement_name in cluster.objects

    res = await client.post(f"/admin/users/{alice_id}/delete", data=_csrf_form(), follow_redirects=False)

    assert res.status_code == 303
    assert profile_store._profile_object_name(alice_id) not in cluster.objects
    assert achievement_name not in cluster.objects


# --- gate on: require_admin's actual authorization boundary -----------------

async def test_admin_page_403_without_login_when_gate_on(client, cluster, monkeypatch):
    monkeypatch.setenv("CLUSTERDRILL_PASSWORD", "some-password")
    res = await client.get("/admin", follow_redirects=False)
    # PasswordGateMiddleware redirects an unauthenticated GET to /login
    # before require_admin is ever reached.
    assert res.status_code == 303
    assert res.headers["location"].startswith("/login")


async def test_admin_page_404s_for_a_logged_in_admin_too_when_gate_on(client, cluster, monkeypatch):
    # Confirms the 404 is single_user_mode(), not the auth boundary itself -
    # a correctly-authenticated admin still gets 404, same as gate-off.
    monkeypatch.setenv("CLUSTERDRILL_PASSWORD", "some-password")
    login_res = await client.post(
        "/login", data={"username": "tester", "password": "test-password-not-real", "next": "/admin"},
    )
    assert login_res.status_code == 303
    res = await client.get("/admin")
    assert res.status_code == 404
