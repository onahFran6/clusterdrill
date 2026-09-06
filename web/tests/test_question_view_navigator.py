"""services/question_view.py's question navigator:
question_context()'s `palette` field and ActiveSession.visited_qids.

Fixture questions never ship a setup.sh (question_bank_factory's default),
so question_context()'s auto-provision branch never fires here - nothing
to mock for that, same reasoning tests/test_question_view_auto_provision.py
documents for its own one_question_bank fixture (which adds setup.sh back
deliberately, for a different concern than this file's own).
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


@pytest.fixture
def three_question_bank(question_bank_factory, monkeypatch):
    bank = question_bank_factory({"topic-a": 3})
    monkeypatch.setattr(question_view, "bank", bank)
    return [q.id for q in bank.questions]


def test_palette_is_empty_outside_a_session(three_question_bank):
    qid = three_question_bank[0]
    ctx = question_view.question_context(qid)
    assert ctx["palette"] == []


def test_palette_lists_every_question_in_session_order(three_question_bank):
    qids = three_question_bank
    session_store.set_active(ActiveSession(mode="fixed", topic="topic-a", question_ids=qids))

    ctx = question_view.question_context(qids[0])

    assert [p["id"] for p in ctx["palette"]] == qids
    assert [p["position"] for p in ctx["palette"]] == [1, 2, 3]


def test_palette_marks_only_the_current_question(three_question_bank):
    qids = three_question_bank
    session_store.set_active(ActiveSession(mode="fixed", topic="topic-a", question_ids=qids))

    ctx = question_view.question_context(qids[1])

    current_flags = {p["id"]: p["current"] for p in ctx["palette"]}
    assert current_flags == {qids[0]: False, qids[1]: True, qids[2]: False}


def test_viewing_a_question_marks_it_visited(three_question_bank):
    qids = three_question_bank
    session = ActiveSession(mode="fixed", topic="topic-a", question_ids=qids)
    session_store.set_active(session)

    assert qids[0] not in session.visited_qids
    question_view.question_context(qids[0])
    assert qids[0] in session.visited_qids
    # Only the viewed one - not the whole session.
    assert qids[1] not in session.visited_qids


def test_palette_status_defaults_to_unvisited(three_question_bank):
    qids = three_question_bank
    session_store.set_active(ActiveSession(mode="fixed", topic="topic-a", question_ids=qids))

    ctx = question_view.question_context(qids[0])

    statuses = {p["id"]: p["status"] for p in ctx["palette"]}
    # qids[0] is visited by the act of viewing it just now; the others
    # never have been.
    assert statuses[qids[1]] == "unvisited"
    assert statuses[qids[2]] == "unvisited"


def test_palette_status_visited_when_seen_but_not_graded(three_question_bank):
    qids = three_question_bank
    session_store.set_active(ActiveSession(mode="fixed", topic="topic-a", question_ids=qids))

    ctx = question_view.question_context(qids[0])

    assert {p["id"]: p["status"] for p in ctx["palette"]}[qids[0]] == "visited"


def test_palette_status_passed(three_question_bank):
    qids = three_question_bank
    session = ActiveSession(mode="fixed", topic="topic-a", question_ids=qids, passed_qids={qids[1]})
    session_store.set_active(session)

    ctx = question_view.question_context(qids[0])

    assert {p["id"]: p["status"] for p in ctx["palette"]}[qids[1]] == "passed"


def test_palette_status_failed(three_question_bank):
    qids = three_question_bank
    session = ActiveSession(mode="fixed", topic="topic-a", question_ids=qids, failed_qids={qids[1]})
    session_store.set_active(session)

    ctx = question_view.question_context(qids[0])

    assert {p["id"]: p["status"] for p in ctx["palette"]}[qids[1]] == "failed"


def test_palette_status_passed_takes_priority_over_failed(three_question_bank):
    # A qid that failed once and was later passed on retry - passed_qids
    # never gets cleared on a later pass (sessions.py), so both sets can
    # contain the same qid at once. The palette should reflect "passing
    # right now," not "has ever failed this session."
    qids = three_question_bank
    session = ActiveSession(
        mode="fixed", topic="topic-a", question_ids=qids,
        passed_qids={qids[1]}, failed_qids={qids[1]},
    )
    session_store.set_active(session)

    ctx = question_view.question_context(qids[0])

    assert {p["id"]: p["status"] for p in ctx["palette"]}[qids[1]] == "passed"
