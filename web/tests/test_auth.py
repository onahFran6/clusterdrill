"""auth.py: session validity, revocation, login rate limiting, CSRF - all
pure logic or logic operating on a plain dict/lightweight fake Request, no
subprocess/I-O. Module-level globals (_revoked_before,
_revoked_before_by_user, _login_failures) are reset between tests by the
autouse fixture below - without it, one test calling revoke_all_sessions()
would silently poison every later test in the same pytest run (the same
single-process-singleton tradeoff sessions.py/idle.py/ttyd_manager.py all
make deliberately for the real app - it just needs explicit handling in
tests).

users.authenticate is monkeypatched (gate_on below) rather than exercised
for real - this file is about auth.py's own session/CSRF/rate-limit logic,
not users.py's kubectl-backed account lookup (that's test_users.py's job).
"""
from __future__ import annotations

import time
from types import SimpleNamespace
from typing import Optional

import auth
import pytest
import users


class FakeRequest:
    """Minimal stand-in for starlette.requests.Request - just enough
    surface (.session, .headers, .client.host) for auth.py's functions,
    none of which need a real ASGI scope."""

    def __init__(self, headers=None, client_host="203.0.113.5"):
        self.session: dict = {}
        self.headers = headers or {}
        self.client = SimpleNamespace(host=client_host) if client_host else None


@pytest.fixture(autouse=True)
def _reset_auth_module_globals():
    auth._revoked_before = 0.0
    auth._revoked_before_by_user.clear()
    auth._login_failures.clear()
    yield
    auth._revoked_before = 0.0
    auth._revoked_before_by_user.clear()
    auth._login_failures.clear()


ALICE = users.User(user_id="alice", username="alice", is_admin=False, created_at="2026-01-01T00:00:00Z")
ALICE_PASSWORD = "correct-horse-battery-staple"


@pytest.fixture
def gate_on(monkeypatch):
    """Turns the gate on and stubs users.authenticate with one fake account
    (ALICE/ALICE_PASSWORD) - real account lookup/hashing is users.py's own
    test file's job, not this one's."""
    monkeypatch.setenv("CLUSTERDRILL_PASSWORD", ALICE_PASSWORD)

    def fake_authenticate(username: str, password: str):
        if username == ALICE.username and password == ALICE_PASSWORD:
            return ALICE
        return None

    monkeypatch.setattr(users, "authenticate", fake_authenticate)
    return ALICE


@pytest.fixture
def gate_off(monkeypatch):
    monkeypatch.delenv("CLUSTERDRILL_PASSWORD", raising=False)


# --- password_gate_enabled ---------------------------------------------------

def test_password_gate_enabled_reflects_env(gate_on):
    assert auth.password_gate_enabled() is True


def test_password_gate_disabled_by_default(gate_off):
    assert auth.password_gate_enabled() is False


# --- session_is_valid / revoke_all_sessions / revoke_user_sessions ----------

def test_session_is_valid_false_for_empty_session():
    assert auth.session_is_valid({}) is False


def test_session_is_valid_false_without_authed_at():
    # Simulates a cookie from before AUTHED_AT_KEY existed - must not be
    # trusted, per session_is_valid's own docstring.
    assert auth.session_is_valid({auth.SESSION_KEY: True}) is False


def test_session_is_valid_false_without_user_id():
    # Simulates an old-style cookie (single shared password, no per-user
    # identity) - must not be trusted either, same reasoning as above.
    session = {auth.SESSION_KEY: True, auth.AUTHED_AT_KEY: time.time()}
    assert auth.session_is_valid(session) is False


def test_session_is_valid_true_for_fresh_login():
    session = {auth.SESSION_KEY: True, auth.AUTHED_AT_KEY: time.time(), auth.USER_ID_KEY: "alice"}
    assert auth.session_is_valid(session) is True


def test_revoke_all_sessions_invalidates_existing_session():
    session = {auth.SESSION_KEY: True, auth.AUTHED_AT_KEY: time.time(), auth.USER_ID_KEY: "alice"}
    assert auth.session_is_valid(session) is True
    auth.revoke_all_sessions()
    assert auth.session_is_valid(session) is False


def test_revoke_all_sessions_does_not_block_a_later_login():
    auth.revoke_all_sessions()
    # authed_at strictly after _revoked_before, not just "time.time() called
    # a moment later" - two time.time() calls back-to-back in a fast test
    # can land in the same clock tick and fail session_is_valid's strict
    # `>` comparison by coincidence, which isn't the thing this test is
    # meant to prove.
    session = {
        auth.SESSION_KEY: True,
        auth.AUTHED_AT_KEY: auth._revoked_before + 1,
        auth.USER_ID_KEY: "alice",
    }
    assert auth.session_is_valid(session) is True


def test_revoke_user_sessions_invalidates_only_that_user():
    alice_session = {auth.SESSION_KEY: True, auth.AUTHED_AT_KEY: time.time(), auth.USER_ID_KEY: "alice"}
    bob_session = {auth.SESSION_KEY: True, auth.AUTHED_AT_KEY: time.time(), auth.USER_ID_KEY: "bob"}
    auth.revoke_user_sessions("alice")
    assert auth.session_is_valid(alice_session) is False
    assert auth.session_is_valid(bob_session) is True


# --- attempt_login / logout --------------------------------------------------

def test_attempt_login_success_stamps_session(gate_on):
    request = FakeRequest()
    user = auth.attempt_login(request, "alice", ALICE_PASSWORD)
    assert user == ALICE
    assert request.session[auth.SESSION_KEY] is True
    assert isinstance(request.session[auth.AUTHED_AT_KEY], float)
    assert request.session[auth.USER_ID_KEY] == "alice"
    assert request.session[auth.USERNAME_KEY] == "alice"
    assert request.session[auth.IS_ADMIN_KEY] is False
    assert request.session[auth.CSRF_SESSION_KEY]
    assert auth.session_is_valid(request.session) is True


def test_attempt_login_failure_leaves_session_empty(gate_on):
    request = FakeRequest()
    assert auth.attempt_login(request, "alice", "wrong") is None
    assert request.session == {}


def test_attempt_login_unknown_username_fails(gate_on):
    request = FakeRequest()
    assert auth.attempt_login(request, "nobody", ALICE_PASSWORD) is None
    assert request.session == {}


def test_logout_clears_all_session_keys(gate_on):
    request = FakeRequest()
    auth.attempt_login(request, "alice", ALICE_PASSWORD)
    assert request.session
    auth.logout(request)
    assert auth.SESSION_KEY not in request.session
    assert auth.AUTHED_AT_KEY not in request.session
    assert auth.USER_ID_KEY not in request.session
    assert auth.USERNAME_KEY not in request.session
    assert auth.IS_ADMIN_KEY not in request.session
    assert auth.CSRF_SESSION_KEY not in request.session


# --- current_user_id / current_username / require_admin ---------------------

def test_current_user_id_and_username_from_session(gate_on):
    request = FakeRequest()
    auth.attempt_login(request, "alice", ALICE_PASSWORD)
    assert auth.current_user_id(request.session) == "alice"
    assert auth.current_username(request.session) == "alice"


def test_current_user_id_none_for_empty_session():
    assert auth.current_user_id({}) is None


def test_require_admin_is_noop_when_gate_disabled(gate_off):
    request = FakeRequest()
    assert auth.require_admin(request) is None


def test_require_admin_rejects_non_admin(gate_on, monkeypatch):
    request = FakeRequest()
    auth.attempt_login(request, "alice", ALICE_PASSWORD)
    monkeypatch.setattr(users, "get_user", lambda user_id: ALICE)
    from fastapi import HTTPException

    with pytest.raises(HTTPException) as exc_info:
        auth.require_admin(request)
    assert exc_info.value.status_code == 403


def test_require_admin_allows_admin(gate_on, monkeypatch):
    admin_user = users.User(user_id="admin", username="admin", is_admin=True, created_at="")
    request = FakeRequest()
    request.session[auth.USER_ID_KEY] = "admin"
    monkeypatch.setattr(users, "get_user", lambda user_id: admin_user)
    assert auth.require_admin(request) == admin_user


# --- login rate limiting -----------------------------------------------------

def test_not_locked_out_initially():
    request = FakeRequest()
    assert auth.seconds_until_unlocked(request) is None


def test_locked_out_after_max_attempts():
    request = FakeRequest()
    for _ in range(auth._LOGIN_MAX_ATTEMPTS):
        auth.record_failed_login(request)
    remaining = auth.seconds_until_unlocked(request)
    assert remaining is not None
    assert 0 < remaining <= auth._LOGIN_LOCKOUT_SECONDS


def test_one_fewer_than_max_attempts_not_locked_out():
    request = FakeRequest()
    for _ in range(auth._LOGIN_MAX_ATTEMPTS - 1):
        auth.record_failed_login(request)
    assert auth.seconds_until_unlocked(request) is None


def test_clear_login_attempts_unlocks():
    request = FakeRequest()
    for _ in range(auth._LOGIN_MAX_ATTEMPTS):
        auth.record_failed_login(request)
    assert auth.seconds_until_unlocked(request) is not None
    auth.clear_login_attempts(request)
    assert auth.seconds_until_unlocked(request) is None


def test_lockout_is_keyed_per_client_not_global():
    attacker = FakeRequest(client_host="198.51.100.1")
    victim = FakeRequest(client_host="198.51.100.2")
    for _ in range(auth._LOGIN_MAX_ATTEMPTS):
        auth.record_failed_login(attacker)
    assert auth.seconds_until_unlocked(attacker) is not None
    assert auth.seconds_until_unlocked(victim) is None


def test_client_key_prefers_cf_connecting_ip_header():
    request = FakeRequest(
        headers={"cf-connecting-ip": "192.0.2.9"}, client_host="127.0.0.1"
    )
    assert auth._client_key(request) == "192.0.2.9"


def test_client_key_falls_back_to_socket_peer():
    request = FakeRequest(headers={}, client_host="192.0.2.10")
    assert auth._client_key(request) == "192.0.2.10"


# --- check_lockout_and_record_attempt (atomic check+record) ------------------

def test_check_lockout_and_record_attempt_allows_first_attempts():
    request = FakeRequest()
    for _ in range(auth._LOGIN_MAX_ATTEMPTS):
        assert auth.check_lockout_and_record_attempt(request) is None


def test_check_lockout_and_record_attempt_locks_out_after_max():
    request = FakeRequest()
    for _ in range(auth._LOGIN_MAX_ATTEMPTS):
        auth.check_lockout_and_record_attempt(request)
    remaining = auth.check_lockout_and_record_attempt(request)
    assert remaining is not None
    assert 0 < remaining <= auth._LOGIN_LOCKOUT_SECONDS


def test_check_lockout_and_record_attempt_does_not_add_to_count_once_locked():
    # Once locked out, further calls must not keep appending to the
    # attempts list (it would keep pushing the lockout's own oldest-count
    # window forward indefinitely) - the failing branch returns without
    # ever calling attempts.append().
    request = FakeRequest()
    for _ in range(auth._LOGIN_MAX_ATTEMPTS):
        auth.check_lockout_and_record_attempt(request)
    before = len(auth._login_failures[auth._client_key(request)])
    auth.check_lockout_and_record_attempt(request)
    auth.check_lockout_and_record_attempt(request)
    after = len(auth._login_failures[auth._client_key(request)])
    assert after == before


def test_check_lockout_and_record_attempt_closes_the_toctou_race():
    """The actual bug this function replaces: login_submit used to call
    seconds_until_unlocked() (acquires+releases the lock) and, on a
    separate later call, record_failed_login() (acquires the lock again) -
    two concurrent requests from the same attacker could both pass the
    first call before either completed the second, letting a burst of
    concurrent guesses slip past _LOGIN_MAX_ATTEMPTS before lockout closed.
    Fire a real burst of concurrent threads at the single combined
    function and confirm the recorded count never exceeds what a
    correctly-serialized sequence would produce - proving the fix is
    actually atomic under real thread contention, not just correct when
    called one at a time.
    """
    import threading

    request = FakeRequest()
    outcomes: list[Optional[int]] = []
    outcomes_lock = threading.Lock()
    concurrency = 50

    def fire():
        result = auth.check_lockout_and_record_attempt(request)
        with outcomes_lock:
            outcomes.append(result)

    threads = [threading.Thread(target=fire) for _ in range(concurrency)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()

    allowed = sum(1 for r in outcomes if r is None)
    locked_out = sum(1 for r in outcomes if r is not None)
    assert allowed == auth._LOGIN_MAX_ATTEMPTS, (
        f"expected exactly {auth._LOGIN_MAX_ATTEMPTS} of {concurrency} concurrent "
        f"attempts to be allowed through, got {allowed} (race not fully closed)"
    )
    assert locked_out == concurrency - auth._LOGIN_MAX_ATTEMPTS
    assert len(auth._login_failures[auth._client_key(request)]) == auth._LOGIN_MAX_ATTEMPTS


# --- CSRF ---------------------------------------------------------------------

def test_get_csrf_token_empty_before_login():
    request = FakeRequest()
    assert auth.get_csrf_token(request) == ""


def test_require_csrf_form_passes_with_correct_token(gate_on):
    request = FakeRequest()
    auth.attempt_login(request, "alice", ALICE_PASSWORD)
    token = auth.get_csrf_token(request)
    auth.require_csrf_form(request, token)  # should not raise


def test_require_csrf_form_rejects_wrong_token(gate_on):
    from fastapi import HTTPException

    request = FakeRequest()
    auth.attempt_login(request, "alice", ALICE_PASSWORD)
    with pytest.raises(HTTPException) as exc_info:
        auth.require_csrf_form(request, "not-the-real-token")
    assert exc_info.value.status_code == 403


def test_require_csrf_form_is_noop_when_gate_disabled(gate_off):
    # No login ever happens with the gate off, so no token is ever issued -
    # CSRF isn't a meaningful threat inside that already-trusted boundary.
    request = FakeRequest()
    auth.require_csrf_form(request, "anything")  # should not raise


def test_csrf_protect_header_passes_with_correct_token(gate_on):
    request = FakeRequest()
    auth.attempt_login(request, "alice", ALICE_PASSWORD)
    request.headers = {"x-csrf-token": auth.get_csrf_token(request)}
    auth.csrf_protect_header(request)  # should not raise


def test_csrf_protect_header_rejects_missing_token(gate_on):
    from fastapi import HTTPException

    request = FakeRequest()
    auth.attempt_login(request, "alice", ALICE_PASSWORD)
    with pytest.raises(HTTPException) as exc_info:
        auth.csrf_protect_header(request)
    assert exc_info.value.status_code == 403


def test_csrf_protect_header_is_noop_when_gate_disabled(gate_off):
    request = FakeRequest()
    auth.csrf_protect_header(request)  # should not raise, no session at all


def test_csrf_protect_header_is_noop_for_invalid_session(gate_on):
    # Not this dependency's job to reject an unauthenticated request -
    # PasswordGateMiddleware already does that before a route (and its
    # dependencies) is ever reached. Confirms it degrades safely if
    # somehow invoked without a valid session instead of raising a
    # confusing 403 that masks the real 401.
    request = FakeRequest()
    auth.csrf_protect_header(request)  # should not raise


# --- safe_next_path (open-redirect guard) ------------------------------------

@pytest.mark.parametrize("raw,expected", [
    (None, "/topics"),
    ("", "/topics"),
    ("not-a-path", "/topics"),
    ("//evil.example.com", "/topics"),
    ("/questions/q101-01", "/questions/q101-01"),
    ("/logout", "/topics"),  # /logout is POST-only - a GET redirect there 405s
])
def test_safe_next_path(raw, expected):
    assert auth.safe_next_path(raw) == expected
