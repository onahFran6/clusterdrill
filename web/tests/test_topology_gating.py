"""Regression coverage: QuestionBank.set_node_count()'s topology
gating (questions.py's Question.is_eligible_for / QuestionBank.questions).

This is the code-path-level half of "prove both exclusion and
inclusion based on server-derived node count" - it exercises
questions.py directly with question_bank_factory's `min_nodes` support
(tests/conftest.py) rather than standing up a real multi-node cluster (CI
should prove the filtering logic, not real infra).
The route-level half (topics, topic detail, sessions, direct question
routes) lives in tests/routes/test_topology_gating_routes.py. A third check
here (test_real_bank_multi_node_question_is_gated_by_node_count) reads the
actual questions/ directory to confirm the one shipped min_nodes: 2
question (pod-design's q103-31) is wired up correctly, not just a synthetic
fixture.
"""
from __future__ import annotations

from pathlib import Path

from questions import QUESTIONS_DIR, Question, QuestionBank


def _question(min_nodes) -> Question:
    return Question(id="q", topic="t", path=Path("/nonexistent"), min_nodes=min_nodes)


def test_is_eligible_for_within_and_below_reported_node_count():
    assert _question(1).is_eligible_for(1) is True
    assert _question(1).is_eligible_for(2) is True
    assert _question(2).is_eligible_for(2) is True
    assert _question(2).is_eligible_for(1) is False


def test_is_eligible_for_zero_reported_nodes_excludes_everything():
    assert _question(1).is_eligible_for(0) is False


def test_is_eligible_for_missing_or_malformed_min_nodes_fails_closed():
    # No min_nodes at all (never-declared requirement) - fails closed rather
    # than being silently treated as "any node count is fine".
    assert _question(None).is_eligible_for(1) is False
    assert _question(None).is_eligible_for(0) is False
    # A bool is technically `isinstance(x, int)` in Python - explicitly
    # rejected so `min_nodes: true` in a hand-edited fragment can't slip
    # through as min_nodes=1.
    assert _question(True).is_eligible_for(5) is False
    # Zero or negative would mean "needs no nodes" / nonsensical - also
    # rejected rather than treated as always-eligible.
    assert _question(0).is_eligible_for(5) is False
    assert _question(-1).is_eligible_for(5) is False


def test_bank_with_no_node_count_set_is_unfiltered(question_bank_factory):
    # Matches every pre-existing test's expectation: a QuestionBank that
    # never had set_node_count() called (the default, e.g. every route test
    # not opting into this gating) returns every discovered question
    # regardless of min_nodes, including questions with no min_nodes at all.
    bank = question_bank_factory({"topic-a": ["easy", "easy"]}, min_nodes={"topic-a": [1, 2]})
    assert len(bank.questions) == 2


def test_set_node_count_one_excludes_two_node_question(question_bank_factory):
    bank = question_bank_factory(
        {"topic-a": ["easy", "medium"]}, min_nodes={"topic-a": [1, 2]}
    )
    bank.set_node_count(1)
    ids = {q.id for q in bank.questions}
    assert ids == {"qT01-question"}
    assert bank.pool_size("topic-a") == 1
    assert bank.get("qT02-question") is None
    assert bank.index_of("qT02-question") is None
    assert bank.excluded_count == 1


def test_set_node_count_two_includes_two_node_question(question_bank_factory):
    bank = question_bank_factory(
        {"topic-a": ["easy", "medium"]}, min_nodes={"topic-a": [1, 2]}
    )
    bank.set_node_count(2)
    ids = {q.id for q in bank.questions}
    assert ids == {"qT01-question", "qT02-question"}
    assert bank.pool_size("topic-a") == 2
    assert bank.get("qT02-question") is not None
    assert bank.index_of("qT02-question") == 1
    assert bank.excluded_count == 0


def test_set_node_count_one_hides_a_topic_entirely_when_every_question_needs_two(
    question_bank_factory,
):
    # A topic whose *whole* pool requires 2 nodes must disappear from
    # topics() entirely on a one-node appliance, not just shrink - this is
    # the "excludes it from Topics" half of this coverage, distinct from
    # the partial-exclusion case above (topic-a still has an eligible
    # question, topic-b has none).
    bank = question_bank_factory(
        {"topic-a": ["easy"], "topic-b": ["easy", "easy"]},
        min_nodes={"topic-a": 1, "topic-b": 2},
    )
    bank.set_node_count(1)
    assert bank.topics() == ["topic-a"]
    assert bank.pool_size("topic-b") == 0

    bank.set_node_count(2)
    assert bank.topics() == ["topic-a", "topic-b"]
    assert bank.pool_size("topic-b") == 2


def test_refresh_preserves_node_count(question_bank_factory):
    # bank.refresh() (called at the top of nearly every route handler - see
    # routers/pages.py, routers/sessions_router.py) must not reset the
    # server-derived topology filter set at startup by app.py's lifespan().
    bank = question_bank_factory(
        {"topic-a": ["easy", "medium"]}, min_nodes={"topic-a": [1, 2]}
    )
    bank.set_node_count(1)
    bank.refresh()
    assert {q.id for q in bank.questions} == {"qT01-question"}


def test_real_bank_multi_node_question_is_gated_by_node_count():
    """Reads the actual questions/ directory (not a fixture) to confirm the
    one shipped requirements.min_nodes: 2 question - pod-design's q103-31 -
    is excluded at node_count=1 and included at node_count=2, proving the
    real fragment entry (not just the test's synthetic data) is wired up
    correctly end to end."""
    qid = "q103-31-podantiaffinity-required-running-on-two-nodes"
    bank = QuestionBank(questions_dir=QUESTIONS_DIR)
    question = next(q for q in bank.questions if q.id == qid)
    assert question.min_nodes == 2

    bank.set_node_count(1)
    assert bank.get(qid) is None
    assert qid not in {q.id for q in bank.questions}

    bank.set_node_count(2)
    assert bank.get(qid) is not None
    assert qid in {q.id for q in bank.questions}
