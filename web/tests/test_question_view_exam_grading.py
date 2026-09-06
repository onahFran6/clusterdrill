"""services/question_view.py's deferred-grading behavior for exam-mode
sessions: no interim feedback, and no reachable
Solution tab either - see question_context()'s own comment for why the
real ANSWER.md text must never even be computed into the page, not merely
hidden client-side.

Fixture questions never ship a setup.sh (question_bank_factory's default),
so question_context()'s auto-provision branch never fires - nothing to
mock for that, same reasoning tests/test_question_view_auto_provision.py
documents for its own one_question_bank fixture.
"""
from __future__ import annotations

import profile_store
import pytest
import services.question_view as question_view
from sessions import ActiveSession
from sessions import store as session_store


@pytest.fixture(autouse=True)
def _isolate_module_globals(monkeypatch, tmp_path):
    question_view._auto_provisioned_qids.clear()
    monkeypatch.setattr(question_view, "WORK_DIR_ROOT", tmp_path / "practice-work")
    empty_profile = profile_store.Profile(spec=dict(profile_store._EMPTY_PROFILE_SPEC))
    monkeypatch.setattr(profile_store, "get_profile", lambda user_id=None: empty_profile)
    session_store.clear()
    yield
    question_view._auto_provisioned_qids.clear()
    session_store.clear()


SECRET_ANSWER_TEXT = "kubectl create configmap catalog-env --from-literal=CATALOG_MODE=readonly"


@pytest.fixture
def one_question_bank(question_bank_factory, monkeypatch):
    bank = question_bank_factory({"topic-a": 1})
    question = bank.questions[0]
    (question.path / "ANSWER.md").write_text(f"# Solution\n\n```\n{SECRET_ANSWER_TEXT}\n```\n")
    monkeypatch.setattr(question_view, "bank", bank)
    return question.id


def _start_session(mode: str, qid: str) -> None:
    session_store.set_active(ActiveSession(mode=mode, topic="topic-a", question_ids=[qid]))


def test_is_exam_session_true_for_an_exam_session(one_question_bank):
    qid = one_question_bank
    _start_session("exam", qid)
    ctx = question_view.question_context(qid)
    assert ctx["is_exam_session"] is True


def test_is_exam_session_false_for_every_other_mode(one_question_bank):
    qid = one_question_bank
    for mode in ("fixed", "randomized", "mixed", "boss", "daily"):
        _start_session(mode, qid)
        ctx = question_view.question_context(qid)
        assert ctx["is_exam_session"] is False


def test_is_exam_session_false_outside_any_session(one_question_bank):
    qid = one_question_bank
    ctx = question_view.question_context(qid)
    assert ctx["is_exam_session"] is False


def test_exam_session_forces_solution_tab_back_to_task(one_question_bank):
    qid = one_question_bank
    _start_session("exam", qid)
    ctx = question_view.question_context(qid, tab="solution")
    assert ctx["tab"] == "task"


def test_non_exam_session_solution_tab_is_unaffected(one_question_bank):
    qid = one_question_bank
    _start_session("fixed", qid)
    ctx = question_view.question_context(qid, tab="solution")
    assert ctx["tab"] == "solution"


def test_exam_session_never_renders_the_real_answer_text(one_question_bank):
    qid = one_question_bank
    _start_session("exam", qid)
    ctx = question_view.question_context(qid, tab="solution")
    assert SECRET_ANSWER_TEXT not in ctx["answer_html"]
    assert ctx["discovery_path_html"] is None


def test_non_exam_session_still_renders_the_real_answer_text(one_question_bank):
    qid = one_question_bank
    _start_session("fixed", qid)
    ctx = question_view.question_context(qid, tab="solution")
    assert SECRET_ANSWER_TEXT in ctx["answer_html"]
