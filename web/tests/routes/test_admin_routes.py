"""Route-level tests for routers/admin_router.py.

Most CRUD tests run with the password gate off (no CLUSTERDRILL_PASSWORD),
same as the rest of tests/routes/ - auth.require_admin and
auth.csrf_protect_form both no-op in that mode (see their own docstrings),
so these tests exercise admin_router's own logic (username/password
validation, self-delete/last-admin guardrails) without extra plumbing.
A separate section covers the require_admin authorization boundary itself
with the gate on.

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
from kube_json import decode_payload


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

    def apply_json(self, obj: dict) -> bool:
        self.objects[obj["metadata"]["name"]] = obj
        return True

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
    monkeypatch.setattr(users, "kubectl_delete", fake.delete)
    monkeypatch.setattr(profile_store, "kubectl_get_json", fake.get_json)
    monkeypatch.setattr(profile_store, "kubectl_apply_json", fake.apply_json)
    monkeypatch.setattr(profile_store, "kubectl_delete", fake.delete)
    monkeypatch.setattr(admin_router, "run_batch_cleanup", lambda *a, **k: None)

    def real_get_user(user_id: str):
        obj = fake.get_json("secret", users._user_object_name(user_id), "-n", users.SYSTEM_NAMESPACE)
        return users._to_user(obj) if obj is not None else None

    monkeypatch.setattr(users, "get_user", real_get_user)
    # Matches conftest.py's fake_user_store TEST_USER (user_id "tester",
    # is_admin=True) so logging in as "tester" resolves to a real admin
    # record here, not a 404 from require_admin's live get_user() lookup.
    users.create_user("tester", "irrelevant-authenticate-is-mocked", is_admin=True)
    return fake


def _csrf_form(csrf_token="anything-when-gate-off", **fields):
    return {"csrf_token": csrf_token, **fields}


# --- gate off: reachable without login, matching local-dev convention ------

async def test_admin_page_reachable_when_gate_off(client, cluster):
    res = await client.get("/admin")
    assert res.status_code == 200
    assert "tester" in res.text


async def test_delete_user_form_requires_themed_confirmation(client, cluster):
    # issue #117 - Delete must not be a bare single-click submit. The
    # actual confirm-or-cancel behavior is a browser-side dialog
    # interaction static/app.js drives (not exercisable through this
    # server-only test client), so this checks the contract the JS relies
    # on: a data-confirm attribute naming the account, and the one shared
    # #confirm-dialog it opens - not literally the old-style unconfirmed
    # delete form, and not a second, different dialog mechanism.
    users.create_user("alice", "hunter22222")
    res = await client.get("/admin")
    assert 'data-confirm="Delete alice? This can\'t be undone."' in res.text
    assert res.text.count('id="confirm-dialog"') == 1


async def test_admin_page_is_hidden_in_single_user_mode(client, cluster, monkeypatch):
    monkeypatch.setenv("CLUSTERDRILL_SINGLE_USER", "true")
    res = await client.get("/admin")
    assert res.status_code == 404


async def test_create_user_appears_in_list(client, cluster):
    res = await client.post(
        "/admin/users", data=_csrf_form(username="alice", password="hunter22222"), follow_redirects=False,
    )
    assert res.status_code == 303
    assert users.get_user_by_username("alice") is not None


# --- Success-message round trip (issue #116 - previously silent success) ---

async def test_create_user_redirects_with_success_code(client, cluster):
    res = await client.post(
        "/admin/users", data=_csrf_form(username="alice", password="hunter22222"), follow_redirects=False,
    )
    assert res.headers["location"] == "/admin?success=added"


async def test_admin_page_renders_success_message_for_known_code(client, cluster):
    res = await client.get("/admin?success=added")
    assert "User added." in res.text


async def test_admin_page_ignores_unknown_success_code(client, cluster):
    # Never trust an arbitrary query-string value as display text - only
    # the fixed codes in admin_router._SUCCESS_MESSAGES render anything.
    res = await client.get("/admin?success=<script>alert(1)</script>")
    assert "<script>" not in res.text


async def test_create_user_is_admin_checkbox(client, cluster):
    await client.post(
        "/admin/users",
        data=_csrf_form(username="alice", password="hunter22222", is_admin="true"),
        follow_redirects=False,
    )
    alice = users.get_user_by_username("alice")
    assert alice.is_admin is True


async def test_create_user_duplicate_username_409(client, cluster):
    users.create_user("alice", "hunter22222")
    res = await client.post("/admin/users", data=_csrf_form(username="alice", password="hunter22222"))
    assert res.status_code == 409


async def test_create_user_short_password_400(client, cluster):
    res = await client.post("/admin/users", data=_csrf_form(username="alice", password="short"))
    assert res.status_code == 400


async def test_reset_password_changes_login(client, cluster):
    # Checks the stored hash directly rather than via users.authenticate() -
    # conftest.py's autouse fake_user_store fixture stubs authenticate()
    # wholesale for its own fixed "tester" account, so it can't tell alice's
    # old password apart from her new one here.
    alice_id = users.create_user("alice", "old-password-1").user_id
    res = await client.post(
        f"/admin/users/{alice_id}/reset-password",
        data=_csrf_form(password="new-password-2"),
        follow_redirects=False,
    )
    assert res.status_code == 303
    stored = decode_payload(cluster.objects[users._user_object_name(alice_id)])
    stored_hash = stored["passwordHash"]
    assert users._verify_password("old-password-1", stored_hash) is False
    assert users._verify_password("new-password-2", stored_hash) is True


async def test_reset_password_missing_user_404(client, cluster):
    res = await client.post("/admin/users/no-such-id/reset-password", data=_csrf_form(password="new-password-2"))
    assert res.status_code == 404


async def test_reset_password_redirects_with_success_code(client, cluster):
    alice_id = users.create_user("alice", "old-password-1").user_id
    res = await client.post(
        f"/admin/users/{alice_id}/reset-password", data=_csrf_form(password="new-password-2"), follow_redirects=False,
    )
    assert res.headers["location"] == "/admin?success=reset"


async def test_delete_user_removes_account(client, cluster):
    users.create_user("alice", "hunter22222")
    alice_id = users.get_user_by_username("alice").user_id
    res = await client.post(f"/admin/users/{alice_id}/delete", data=_csrf_form(), follow_redirects=False)
    assert res.status_code == 303
    assert users.get_user_by_username("alice") is None


async def test_delete_user_redirects_with_success_code(client, cluster):
    users.create_user("bob", "hunter22222")
    bob_id = users.get_user_by_username("bob").user_id
    res = await client.post(f"/admin/users/{bob_id}/delete", data=_csrf_form(), follow_redirects=False)
    assert res.headers["location"] == "/admin?success=deleted"


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
    import auth

    users.create_user("otheradmin", "hunter22222", is_admin=True)
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
# achievement state) running with no owner.

async def test_delete_user_schedules_namespace_cleanup_for_every_bank_question(client, cluster, monkeypatch):
    from unittest.mock import MagicMock

    from grading_client import ResetResult

    from questions import bank

    mock_cleanup = MagicMock(return_value=ResetResult(ok=True, output=""))
    monkeypatch.setattr(admin_router, "run_batch_cleanup", mock_cleanup)
    alice_id = users.create_user("alice", "hunter22222").user_id

    res = await client.post(f"/admin/users/{alice_id}/delete", data=_csrf_form(), follow_redirects=False)

    assert res.status_code == 303
    mock_cleanup.assert_called_once()
    call_args = mock_cleanup.call_args.args
    assert call_args[0] == [q.id for q in bank.questions]
    assert call_args[2] == alice_id


async def test_delete_user_clears_active_session(client, cluster, monkeypatch):
    from sessions import ActiveSession
    from sessions import store as session_store

    alice_id = users.create_user("alice", "hunter22222").user_id
    session_store.set_active(ActiveSession(question_ids=["q1"], mode="fixed", topic="topic-a"), alice_id)
    assert session_store.get(alice_id) is not None

    res = await client.post(f"/admin/users/{alice_id}/delete", data=_csrf_form(), follow_redirects=False)

    assert res.status_code == 303
    assert session_store.get(alice_id) is None


async def test_delete_user_clears_auto_provision_cache_for_that_user_only(client, cluster):
    from services import question_view

    alice_id = users.create_user("alice", "hunter22222").user_id
    bob_id = users.create_user("bob", "hunter22222").user_id
    question_view._auto_provisioned_qids.add(("q101-01-example", alice_id))
    question_view._auto_provisioned_qids.add(("q101-01-example", bob_id))

    res = await client.post(f"/admin/users/{alice_id}/delete", data=_csrf_form(), follow_redirects=False)

    assert res.status_code == 303
    assert ("q101-01-example", alice_id) not in question_view._auto_provisioned_qids
    assert ("q101-01-example", bob_id) in question_view._auto_provisioned_qids
    question_view._auto_provisioned_qids.clear()


async def test_delete_user_removes_profile_and_achievement_state(client, cluster):
    alice_id = users.create_user("alice", "hunter22222").user_id
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


async def test_admin_page_200_for_logged_in_admin_when_gate_on(client, cluster, monkeypatch):
    monkeypatch.setenv("CLUSTERDRILL_PASSWORD", "some-password")
    login_res = await client.post(
        "/login", data={"username": "tester", "password": "test-password-not-real", "next": "/admin"},
    )
    assert login_res.status_code == 303
    res = await client.get("/admin")
    assert res.status_code == 200
