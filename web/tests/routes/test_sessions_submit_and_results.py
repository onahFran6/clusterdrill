"""Route-level tests for POST /sessions/submit and GET /sessions/results.

check.sh here is the real fixture script (question_bank_factory writes
`echo 'SCORE: 0/0'` by default, overridden per-question below where a
specific pass/fail outcome matters) - run_check really executes
`bash check.sh`, which is safe (no kubectl involved), unlike setup.sh/
reset, which stay mocked everywhere else in this test suite.
run_batch_cleanup and profile_store.record_exam_attempt are still always
mocked - both shell out to kubectl for real otherwise, same reasoning as
test_sessions_routes.py's module docstring and test_questions_routes.py's
_mock_check.
"""
from __future__ import annotations

from unittest.mock import MagicMock

import profile_store
import routers.sessions_router as sessions_router
from grading_client import ResetResult
from sessions import ActiveSession, exam_result_store
from sessions import store as session_store


def _set_check_sh(question, passed: int, total: int) -> None:
    question.path.joinpath("check.sh").write_text(
        f"#!/usr/bin/env bash\necho 'SCORE: {passed}/{total}'\n"
    )


def _mock_cleanup(monkeypatch):
    monkeypatch.setattr(
        sessions_router, "run_batch_cleanup", MagicMock(return_value=ResetResult(ok=True, output="")),
    )


def _mock_record_exam_attempt(monkeypatch):
    mock = MagicMock()
    monkeypatch.setattr(profile_store, "record_exam_attempt", mock)
    return mock


# --- POST /sessions/submit ---------------------------------------------

async def test_submit_exam_no_active_session_is_400(client, fake_bank):
    res = await client.post("/sessions/submit")
    assert res.status_code == 400
    assert session_store.get() is None


async def test_submit_exam_non_exam_session_is_400(client, fake_bank):
    session_store.set_active(ActiveSession(mode="fixed", topic="topic-a", question_ids=["qT01-question"]))
    res = await client.post("/sessions/submit")
    assert res.status_code == 400
    # A 400 must not have torn down the still-live Fixed session.
    assert session_store.get() is not None


async def test_submit_exam_grades_every_question_and_returns_the_score(
    client, question_bank_factory, wire_fake_bank, monkeypatch,
):
    bank = wire_fake_bank(question_bank_factory({"alpha-topic": 3}))
    qids = [q.id for q in bank.questions]
    _set_check_sh(bank.get(qids[0]), passed=1, total=1)
    _set_check_sh(bank.get(qids[1]), passed=0, total=1)
    _set_check_sh(bank.get(qids[2]), passed=1, total=1)
    session_store.set_active(ActiveSession(mode="exam", topic=None, question_ids=qids))
    _mock_cleanup(monkeypatch)
    _mock_record_exam_attempt(monkeypatch)

    res = await client.post("/sessions/submit")

    assert res.status_code == 200
    assert res.json() == {"ok": True, "score": 2, "total": 3}


async def test_submit_exam_records_an_exam_attempt(
    client, question_bank_factory, wire_fake_bank, monkeypatch,
):
    bank = wire_fake_bank(question_bank_factory({"alpha-topic": 2}))
    qids = [q.id for q in bank.questions]
    _set_check_sh(bank.get(qids[0]), passed=1, total=1)
    _set_check_sh(bank.get(qids[1]), passed=0, total=1)
    session_store.set_active(ActiveSession(mode="exam", topic=None, question_ids=qids))
    _mock_cleanup(monkeypatch)
    mock_record = _mock_record_exam_attempt(monkeypatch)

    await client.post("/sessions/submit")

    mock_record.assert_called_once()
    kwargs = mock_record.call_args.kwargs
    assert kwargs["score"] == 1
    assert kwargs["total"] == 2


async def test_submit_exam_domain_breakdown_is_per_domain_not_pooled(
    client, question_bank_factory, wire_fake_bank, monkeypatch,
):
    # Two topics -> two distinct domains (question_bank_factory derives
    # domain from topic name) - alpha-topic's one question passes,
    # beta-topic's one question fails, so the breakdown must show 100%/0%,
    # not a single pooled 50%.
    bank = wire_fake_bank(question_bank_factory({"alpha-topic": 1, "beta-topic": 1}))
    alpha_qid = next(q.id for q in bank.questions if q.topic == "alpha-topic")
    beta_qid = next(q.id for q in bank.questions if q.topic == "beta-topic")
    _set_check_sh(bank.get(alpha_qid), passed=1, total=1)
    _set_check_sh(bank.get(beta_qid), passed=0, total=1)
    session_store.set_active(ActiveSession(mode="exam", topic=None, question_ids=[alpha_qid, beta_qid]))
    _mock_cleanup(monkeypatch)
    mock_record = _mock_record_exam_attempt(monkeypatch)

    await client.post("/sessions/submit")

    domain_breakdown = mock_record.call_args.kwargs["domain_breakdown"]
    assert domain_breakdown["alpha-topic domain"] == 100
    assert domain_breakdown["beta-topic domain"] == 0


async def test_submit_exam_clears_the_active_session(
    client, question_bank_factory, wire_fake_bank, monkeypatch,
):
    bank = wire_fake_bank(question_bank_factory({"alpha-topic": 1}))
    qid = bank.questions[0].id
    session_store.set_active(ActiveSession(mode="exam", topic=None, question_ids=[qid]))
    _mock_cleanup(monkeypatch)
    _mock_record_exam_attempt(monkeypatch)

    await client.post("/sessions/submit")

    assert session_store.get() is None


async def test_submit_exam_schedules_cleanup_for_every_question(
    client, question_bank_factory, wire_fake_bank, monkeypatch,
):
    bank = wire_fake_bank(question_bank_factory({"alpha-topic": 2}))
    qids = [q.id for q in bank.questions]
    session_store.set_active(ActiveSession(mode="exam", topic=None, question_ids=qids))
    mock_cleanup = MagicMock(return_value=ResetResult(ok=True, output=""))
    monkeypatch.setattr(sessions_router, "run_batch_cleanup", mock_cleanup)
    _mock_record_exam_attempt(monkeypatch)

    await client.post("/sessions/submit")

    mock_cleanup.assert_called_once()
    assert mock_cleanup.call_args.args[0] == qids


async def test_submit_exam_populates_the_exam_result_store(
    client, question_bank_factory, wire_fake_bank, monkeypatch,
):
    bank = wire_fake_bank(question_bank_factory({"alpha-topic": 2}))
    qids = [q.id for q in bank.questions]
    _set_check_sh(bank.get(qids[0]), passed=1, total=1)
    _set_check_sh(bank.get(qids[1]), passed=0, total=1)
    session_store.set_active(ActiveSession(mode="exam", topic=None, question_ids=qids))
    _mock_cleanup(monkeypatch)
    _mock_record_exam_attempt(monkeypatch)

    await client.post("/sessions/submit")

    result = exam_result_store.get()
    assert result.score == 1
    assert result.total == 2
    assert [q["id"] for q in result.questions] == qids
    assert [q["passed"] for q in result.questions] == [True, False]


async def test_submit_exam_missing_check_sh_counts_as_failed(
    client, question_bank_factory, wire_fake_bank, monkeypatch,
):
    # question_bank_factory always writes a check.sh - simulate a question
    # missing one entirely (a real, if rare, on-disk state) rather than
    # crashing the whole submission over one bad question.
    bank = wire_fake_bank(question_bank_factory({"alpha-topic": 1}))
    qid = bank.questions[0].id
    bank.get(qid).check_sh.unlink()
    session_store.set_active(ActiveSession(mode="exam", topic=None, question_ids=[qid]))
    _mock_cleanup(monkeypatch)
    _mock_record_exam_attempt(monkeypatch)

    res = await client.post("/sessions/submit")

    assert res.status_code == 200
    assert res.json() == {"ok": True, "score": 0, "total": 1}


# --- GET /sessions/results -----------------------------------------------

async def test_results_page_redirects_to_mock_exam_when_nothing_submitted(client, fake_bank):
    res = await client.get("/sessions/results", follow_redirects=False)
    assert res.status_code in (302, 307)
    assert res.headers["location"] == "/mock-exam"


async def test_results_page_renders_after_a_submission(
    client, question_bank_factory, wire_fake_bank, monkeypatch,
):
    bank = wire_fake_bank(question_bank_factory({"alpha-topic": 2}))
    qids = [q.id for q in bank.questions]
    _set_check_sh(bank.get(qids[0]), passed=1, total=1)
    _set_check_sh(bank.get(qids[1]), passed=0, total=1)
    session_store.set_active(ActiveSession(mode="exam", topic=None, question_ids=qids))
    _mock_cleanup(monkeypatch)
    _mock_record_exam_attempt(monkeypatch)

    submit_res = await client.post("/sessions/submit")
    assert submit_res.status_code == 200

    res = await client.get("/sessions/results")
    assert res.status_code == 200
    assert "50%" in res.text  # 1/2
    assert qids[0] in res.text
    assert qids[1] in res.text
