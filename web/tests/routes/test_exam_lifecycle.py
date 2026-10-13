"""Real request paths plus scheduler/concurrency checks with disposable state."""
from __future__ import annotations

import time
from concurrent.futures import ThreadPoolExecutor
from unittest.mock import MagicMock

import app as app_module
import auth
import profile_store
import pytest
from grading_client import CheckResult, ResetResult
from idle import tracker as idle_tracker
from services import question_view, session_lifecycle
from sessions import ActiveSession, exam_result_store
from sessions import store as session_store


@pytest.fixture(autouse=True)
def isolated_lifecycle(monkeypatch, fake_bank):
    monkeypatch.setattr(auth, "_revoked_before", 0)
    monkeypatch.setattr(auth, "_login_failures", {})
    monkeypatch.setattr(question_view, "_auto_provisioned_qids", set())
    monkeypatch.setattr(app_module.ttyd_manager, "kill_all_tmux_sessions", MagicMock())
    grade = MagicMock(return_value=CheckResult(ok=True, passed=1, total=1, criteria=[], raw_stdout="", raw_stderr="", error=None))
    record = MagicMock()
    cleanup = MagicMock(return_value=ResetResult(ok=True, output=""))
    freeze = MagicMock(return_value=ResetResult(ok=True, output=""))
    monkeypatch.setattr(session_lifecycle, "run_check", grade)
    monkeypatch.setattr(profile_store, "record_exam_attempt", record)
    monkeypatch.setattr(session_lifecycle, "run_batch_cleanup", cleanup)
    monkeypatch.setattr(session_lifecycle, "run_freeze_exam_namespaces", freeze)
    yield grade, record, cleanup, freeze
    session_store.clear_all()
    idle_tracker.touch()


def exam(user_id=None):
    session = ActiveSession(mode="exam", topic=None, question_ids=["qT01-question", "qT02-question"],
                            started_at=time.time() - 3600, deadline=time.time() - 1, timer_enabled=True)
    session_store.set_active(session, user_id)
    return session


async def test_closed_browser_exam_expires_and_duplicate_submit_returns_result(client, isolated_lifecycle):
    session = exam()
    await app_module._finalize_due_exams()
    assert session_store.get() is None
    result = exam_result_store.get()
    assert result.score == 2
    assert result.reason == "deadline"
    assert result.duration_sec == 3599
    response = await client.post(f"/sessions/submit?attempt_id={session.attempt_id}")
    assert response.status_code == 200
    grade, record, cleanup, freeze = isolated_lifecycle
    assert grade.call_count == 2
    record.assert_called_once()
    cleanup.assert_called_once()
    freeze.assert_called_once()
    response = await client.get("/questions/qT01-question", follow_redirects=False)
    assert response.headers["location"] == "/sessions/results"


def test_finalize_exam_freezes_namespace_access_before_grading_any_question(isolated_lifecycle):
    # R11: the candidate's own RBAC grant must already be gone before
    # check.sh runs for even the first question - otherwise their
    # kubeconfig (and an already-open terminal) stays writable for the
    # entire grading pass, racing the state being evaluated.
    grade, record, cleanup, freeze = isolated_lifecycle
    order: list[str] = []
    freeze.side_effect = lambda *a, **kw: order.append("frozen") or ResetResult(ok=True, output="")
    grade.side_effect = lambda *a, **kw: order.append("graded") or CheckResult(
        ok=True, passed=1, total=1, criteria=[], raw_stdout="", raw_stderr="", error=None,
    )

    session = exam()
    session_lifecycle.finalize_exam(None, session.attempt_id)

    assert order == ["frozen", "graded", "graded"]


def test_finalize_exam_kills_the_terminal_before_grading_any_question(isolated_lifecycle, monkeypatch):
    # R11's actually-effective live mechanism (ADR 0010): the terminal in
    # the single-trusted-operator app has no narrower RBAC grant to revoke
    # (see run_freeze_exam_namespaces's own docstring), so killing the
    # tmux session outright is what really stops further mutation -
    # must happen before check.sh runs for even the first question.
    grade, record, cleanup, freeze = isolated_lifecycle
    order: list[str] = []
    kill = MagicMock(side_effect=lambda user_id: order.append(("killed", user_id)))
    monkeypatch.setattr(session_lifecycle.ttyd_manager, "kill_user_tmux_sessions", kill)
    grade.side_effect = lambda *a, **kw: order.append(("graded", None)) or CheckResult(
        ok=True, passed=1, total=1, criteria=[], raw_stdout="", raw_stderr="", error=None,
    )

    session = exam("alice")
    session_lifecycle.finalize_exam("alice", session.attempt_id)

    assert order == [("killed", "alice"), ("graded", None), ("graded", None)]


def test_parallel_deadline_and_manual_submissions_grade_once(isolated_lifecycle):
    session = exam()
    with ThreadPoolExecutor(max_workers=8) as pool:
        jobs = [pool.submit(session_lifecycle.finalize_exam, None, session.attempt_id) for _ in range(8)]
        jobs += [pool.submit(session_lifecycle.expire_exam, None, session.attempt_id)]
        for job in jobs:
            job.result(timeout=5)
    grade, record, cleanup, freeze = isolated_lifecycle
    assert grade.call_count == 2
    record.assert_called_once()
    cleanup.assert_called_once()


async def test_persistence_retry_keeps_original_grading(isolated_lifecycle):
    session = exam()
    grade, record, cleanup, freeze = isolated_lifecycle
    record.side_effect = [RuntimeError("profile unavailable"), None]
    await app_module._finalize_due_exams()
    assert session_store.get() is session
    assert grade.call_count == 2
    cleanup.assert_not_called()
    grade.side_effect = AssertionError("Must not grade the changed cluster again")
    await app_module._finalize_due_exams()
    assert session_store.get() is None
    assert exam_result_store.get().score == 2
    cleanup.assert_called_once()


async def test_stale_deadline_work_cannot_finish_replacement_attempt(isolated_lifecycle):
    old = exam()
    replacement = ActiveSession(mode="exam", topic=None, question_ids=["qT03-question"], deadline=time.time() + 3600)
    session_store.set_active(replacement)
    session_lifecycle.expire_exam(None, old.attempt_id)
    assert session_store.get() is replacement
    isolated_lifecycle[0].assert_not_called()


@pytest.mark.parametrize("mode", ["fixed", "exam"])
async def test_authenticated_idle_relogin_restores_attempt_position_and_files(client, monkeypatch, mode):
    monkeypatch.setenv("CLUSTERDRILL_PASSWORD", "enabled-for-test")
    login = {"username": "tester", "password": "test-password-not-real"}
    assert (await client.post("/login", data=login)).status_code == 303
    session = ActiveSession(mode=mode, topic="topic-a", question_ids=["qT01-question", "qT02-question"],
                            deadline=time.time() + 3600)
    session_store.set_active(session, "tester")
    await client.get("/questions/qT02-question")
    workdir = question_view.question_workdir("qT02-question")
    (workdir / "answer.txt").write_text("external work")
    idle_tracker.last_activity = time.time() - 601
    assert idle_tracker.should_kill
    await app_module._perform_idle_kill()
    assert (await client.get("/idle-status")).status_code == 401
    assert session_store.get("tester") is session
    response = await client.post("/login", data=login)
    assert response.headers["location"] == "/questions/qT02-question"
    assert (workdir / "answer.txt").read_text() == "external work"
    assert session.current_qid == "qT02-question"
    assert session.deadline > time.time()


async def test_authenticated_expired_exam_returns_results_after_login(client, monkeypatch):
    monkeypatch.setenv("CLUSTERDRILL_PASSWORD", "enabled-for-test")
    login = {"username": "tester", "password": "test-password-not-real"}
    await client.post("/login", data=login)
    session = exam("tester")
    await app_module._perform_idle_kill()
    await app_module._finalize_due_exams()
    response = await client.post("/login", data=login)
    assert response.headers["location"] == "/sessions/results"
    assert exam_result_store.get("tester").attempt_id == session.attempt_id


async def test_end_exam_uses_final_grading_and_stale_submit_cannot_grade_new_attempt(client, isolated_lifecycle):
    old = exam()
    response = await client.post("/sessions/end")
    assert response.status_code == 200
    replacement = ActiveSession(mode="exam", topic=None, question_ids=["qT03-question"])
    session_lifecycle.replace_session(replacement)
    response = await client.post(f"/sessions/submit?attempt_id={old.attempt_id}")
    assert response.status_code == 200
    assert session_store.get() is replacement
    assert isolated_lifecycle[0].call_count == 2


async def test_scheduler_leaves_unexpired_exam_and_practice_alone(isolated_lifecycle):
    session = exam()
    session.deadline = time.time() + 60
    practice = ActiveSession(mode="fixed", topic=None, question_ids=["qT03-question"], deadline=time.time() - 1)
    session_store.set_active(practice, "other")
    await app_module._finalize_due_exams()
    assert session_store.get() is session
    assert session_store.get("other") is practice
    isolated_lifecycle[0].assert_not_called()
