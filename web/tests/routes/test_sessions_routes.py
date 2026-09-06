"""Route-level tests for routers/sessions_router.py.

IMPORTANT: /sessions/end schedules grading_client.run_batch_cleanup as a
FastAPI BackgroundTask, which - if not mocked - would shell out to the
REAL lib/grading.sh against the REAL questions/lib directory (LIB_DIR),
which itself calls real kubectl. Background tasks execute synchronously as
part of request handling under httpx.ASGITransport (same as TestClient),
so every test here that ends a real (non-empty) session explicitly mocks
run_batch_cleanup - never leave it unmocked, tests/conftest.py's
subprocess safety net can't see inside what a `bash -c '...'` call spawns
further, only its own direct argv[0].
"""
from __future__ import annotations

from unittest.mock import MagicMock

import routers.sessions_router as sessions_router
from grading_client import ResetResult
from sessions import store as session_store


def _csrf_form(mode="fixed", topic="topic-a", csrf_token="anything-when-gate-off"):
    return {"mode": mode, "topic": topic, "csrf_token": csrf_token}


async def test_start_session_fixed_redirects_into_first_question(client, fake_bank):
    res = await client.post("/sessions/start", data=_csrf_form(), follow_redirects=False)
    assert res.status_code == 303
    assert session_store.get() is not None
    assert session_store.get().mode == "fixed"
    assert res.headers["location"] == f"/questions/{session_store.get().question_ids[0]}"


async def test_start_session_unknown_mode_400(client, fake_bank):
    res = await client.post("/sessions/start", data=_csrf_form(mode="bogus"))
    assert res.status_code == 400


async def test_start_session_unknown_topic_404(client, fake_bank):
    res = await client.post("/sessions/start", data=_csrf_form(topic="no-such-topic"))
    assert res.status_code == 404


async def test_start_session_mixed_ignores_topic_field(client, fake_bank):
    res = await client.post("/sessions/start", data=_csrf_form(mode="mixed", topic=""), follow_redirects=False)
    assert res.status_code == 303
    assert session_store.get().mode == "mixed"
    assert session_store.get().topic is None


async def test_start_session_missing_csrf_field_succeeds_when_gate_disabled(client, fake_bank):
    # auth.csrf_protect_form's csrf_token is Optional[str] = Form(None), not
    # a required Form(...) field (auth.py's own docstring: "The field is
    # optional at the request-parser level because an intentionally
    # password-free localhost deployment does not mint one") - so a form
    # POST with no csrf_token field at all never 422s regardless of gate
    # state, and with the gate off (this fixture's default, no
    # CLUSTERDRILL_PASSWORD set) require_csrf_form is itself a no-op. This
    # was previously asserted as a 422, which stopped matching that
    # documented behavior; see the companion test right below for the
    # gate-enabled case, where an absent token is correctly rejected (403,
    # same as a wrong one), not merely accepted as a parser default.
    res = await client.post(
        "/sessions/start", data={"mode": "fixed", "topic": "topic-a"}, follow_redirects=False,
    )
    assert res.status_code == 303


async def test_start_session_missing_csrf_field_is_403_when_gate_enabled(client, fake_bank, monkeypatch):
    # Same login-first reasoning as test_start_session_wrong_csrf_token_403_
    # when_gate_enabled below - isolates the CSRF check from the password
    # gate's own redirect.
    monkeypatch.setenv("CLUSTERDRILL_PASSWORD", "some-password")
    login_res = await client.post(
        "/login", data={"username": "tester", "password": "test-password-not-real", "next": "/topics"}
    )
    assert login_res.status_code == 303

    res = await client.post("/sessions/start", data={"mode": "fixed", "topic": "topic-a"})
    assert res.status_code == 403


async def test_start_session_wrong_csrf_token_403_when_gate_enabled(client, fake_bank, monkeypatch):
    # Must actually log in first - enabling the gate with no valid session
    # cookie makes PasswordGateMiddleware itself redirect to /login before
    # the route (and its CSRF check) is ever reached, which would give a
    # false pass here (a 303 for the wrong reason). Logging in first
    # isolates the CSRF check specifically.
    # Username/password match conftest.py's fake_user_store fixture (autouse),
    # which stubs users.authenticate so this doesn't hit real kubectl.
    monkeypatch.setenv("CLUSTERDRILL_PASSWORD", "some-password")
    login_res = await client.post(
        "/login", data={"username": "tester", "password": "test-password-not-real", "next": "/topics"}
    )
    assert login_res.status_code == 303  # httpx persists the Set-Cookie regardless of following it

    res = await client.post("/sessions/start", data=_csrf_form(csrf_token="definitely-wrong"))
    assert res.status_code == 403


async def test_start_session_difficulty_and_timer_minutes_pass_through(client, question_bank_factory, wire_fake_bank):
    bank = wire_fake_bank(question_bank_factory({"topic-a": ["easy", "hard", "hard"]}))

    res = await client.post(
        "/sessions/start",
        data=_csrf_form(topic="topic-a") | {"difficulty": "hard", "timer_minutes": "30"},
        follow_redirects=False,
    )
    assert res.status_code == 303
    session = session_store.get()
    assert len(session.question_ids) == 2
    assert all(bank.get(qid).difficulty == "hard" for qid in session.question_ids)
    assert session.timer_duration_seconds == 30 * 60


async def test_start_session_unknown_difficulty_is_ignored(client, fake_bank):
    # An invalid/forged difficulty value must never 500 or leak through as
    # a literal filter string - it's coerced to "no filter" (routers/
    # sessions_router.py), same as an unknown status filter elsewhere.
    res = await client.post(
        "/sessions/start", data=_csrf_form() | {"difficulty": "impossible"}, follow_redirects=False,
    )
    assert res.status_code == 303
    assert session_store.get() is not None


# --- True exam-condition mock exam ------------------

async def test_start_exam_defaults_redirect_into_first_question(client, fake_bank):
    res = await client.post(
        "/sessions/start", data=_csrf_form(mode="exam", topic=""), follow_redirects=False,
    )
    assert res.status_code == 303
    session = session_store.get()
    assert session.mode == "exam"
    assert session.topic is None
    assert res.headers["location"] == f"/questions/{session.question_ids[0]}"


async def test_start_exam_topics_difficulties_and_count_pass_through(client, question_bank_factory, wire_fake_bank):
    bank = wire_fake_bank(question_bank_factory({
        "alpha-topic": ["easy", "hard", "hard", "hard", "hard"],
        "beta-topic": ["easy", "easy", "easy"],
    }))

    res = await client.post(
        "/sessions/start",
        data={
            "mode": "exam",
            "csrf_token": "anything-when-gate-off",
            "topics": ["alpha-topic"],
            "difficulties": ["hard"],
            "question_count": "20",
        },
        follow_redirects=False,
    )
    assert res.status_code == 303
    session = session_store.get()
    assert len(session.question_ids) == 4
    assert all(bank.get(qid).topic == "alpha-topic" for qid in session.question_ids)
    assert all(bank.get(qid).difficulty == "hard" for qid in session.question_ids)


async def test_start_exam_unknown_topic_404(client, fake_bank):
    res = await client.post(
        "/sessions/start",
        data={"mode": "exam", "csrf_token": "x", "topics": ["no-such-topic"]},
    )
    assert res.status_code == 404
    assert session_store.get() is None


async def test_start_exam_unknown_difficulty_is_ignored_not_500(client, fake_bank):
    res = await client.post(
        "/sessions/start",
        data={"mode": "exam", "csrf_token": "x", "difficulties": ["impossible"]},
        follow_redirects=False,
    )
    assert res.status_code == 303
    assert session_store.get() is not None


async def test_start_exam_out_of_preset_question_count_falls_back_to_default(client, fake_bank):
    from sessions import EXAM_DEFAULT_QUESTION_COUNT

    res = await client.post(
        "/sessions/start",
        data={"mode": "exam", "csrf_token": "x", "question_count": "7"},
        follow_redirects=False,
    )
    assert res.status_code == 303
    assert len(session_store.get().question_ids) <= EXAM_DEFAULT_QUESTION_COUNT


# --- Boss mini-exam start -------------------------------------------

async def test_start_boss_locked_is_403(client, fake_bank, monkeypatch):
    import profile_store
    monkeypatch.setattr(profile_store, "boss_unlocked", lambda topic, user_id=None: False)
    res = await client.post(
        "/sessions/start-boss", data={"topic": "topic-a", "csrf_token": "x"}, follow_redirects=False,
    )
    assert res.status_code == 403
    assert session_store.get() is None


async def test_start_boss_unlocked_redirects_into_first_question(client, fake_bank, monkeypatch):
    import profile_store
    monkeypatch.setattr(profile_store, "boss_unlocked", lambda topic, user_id=None: True)
    res = await client.post(
        "/sessions/start-boss", data={"topic": "topic-a", "csrf_token": "x"}, follow_redirects=False,
    )
    assert res.status_code == 303
    session = session_store.get()
    assert session is not None
    assert session.mode == "boss"
    assert session.topic == "topic-a"
    assert res.headers["location"] == f"/questions/{session.question_ids[0]}"


async def test_start_boss_unknown_topic_404(client, fake_bank, monkeypatch):
    import profile_store
    monkeypatch.setattr(profile_store, "boss_unlocked", lambda topic, user_id=None: True)
    res = await client.post("/sessions/start-boss", data={"topic": "no-such-topic", "csrf_token": "x"})
    assert res.status_code == 404


# --- Daily/session mixed challenge start ----------------------------

async def test_start_daily_redirects_into_first_question(client, fake_bank):
    res = await client.post("/sessions/start-daily", data={"csrf_token": "x"}, follow_redirects=False)
    assert res.status_code == 303
    session = session_store.get()
    assert session is not None
    assert session.mode == "daily"
    assert session.topic is None
    assert res.headers["location"] == f"/questions/{session.question_ids[0]}"


async def test_start_daily_has_no_unlock_gate(client, fake_bank, monkeypatch):
    # Unlike start-boss, there is no profile_store.boss_unlocked-style gate
    # here at all - the daily challenge is always available.
    import profile_store
    monkeypatch.setattr(profile_store, "has_achievement", lambda name, user_id=None: False)
    res = await client.post("/sessions/start-daily", data={"csrf_token": "x"}, follow_redirects=False)
    assert res.status_code == 303


async def test_end_session_noop_when_nothing_active(client, fake_bank, monkeypatch):
    # No session started - run_batch_cleanup must never be called.
    mock_cleanup = MagicMock()
    monkeypatch.setattr(sessions_router, "run_batch_cleanup", mock_cleanup)
    res = await client.post("/sessions/end")
    assert res.status_code == 200
    assert res.json() == {"ok": True}
    mock_cleanup.assert_not_called()


async def test_end_session_clears_active_session_and_schedules_cleanup(client, fake_bank, monkeypatch):
    mock_cleanup = MagicMock(return_value=ResetResult(ok=True, output=""))
    monkeypatch.setattr(sessions_router, "run_batch_cleanup", mock_cleanup)

    start_res = await client.post("/sessions/start", data=_csrf_form(), follow_redirects=False)
    assert start_res.status_code == 303
    assert session_store.get() is not None
    started_qids = list(session_store.get().question_ids)

    end_res = await client.post("/sessions/end")
    assert end_res.status_code == 200
    assert session_store.get() is None
    mock_cleanup.assert_called_once()
    called_qids = mock_cleanup.call_args.args[0]
    assert called_qids == started_qids
