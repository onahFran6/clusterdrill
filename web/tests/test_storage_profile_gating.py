"""Regression coverage: QuestionBank.set_storage_profile()'s
gating (questions.py's Question.is_storage_eligible_for / QuestionBank.questions).

Mirrors test_topology_gating.py's structure and split (code-path-level
gating here via question_bank_factory's `storage_profile` support; route-
level coverage, if any is added, would live under tests/routes/). A final
check here reads the actual questions/ directory to confirm the five
shipped requirements.storage_profile: minikube questions are wired up correctly, not just a synthetic fixture.

The key semantic difference from min_nodes, deliberately tested here: a
missing storage_profile means "no constraint" (fail-*open*), not fail-
closed - see Question.is_storage_eligible_for's docstring for why.
"""
from __future__ import annotations

from pathlib import Path

from questions import QUESTIONS_DIR, Question, QuestionBank


def _question(storage_profile) -> Question:
    return Question(id="q", topic="t", path=Path("/nonexistent"), storage_profile=storage_profile)


def test_is_storage_eligible_for_matching_active_profile():
    assert _question("minikube").is_storage_eligible_for("minikube") is True
    assert _question("local-path").is_storage_eligible_for("local-path") is True


def test_is_storage_eligible_for_mismatched_active_profile():
    assert _question("minikube").is_storage_eligible_for("local-path") is False
    assert _question("local-path").is_storage_eligible_for("minikube") is False


def test_is_storage_eligible_for_no_declared_requirement_is_fail_open():
    # Unlike min_nodes, a question with no storage_profile at all is
    # eligible under *any* active profile, including an unknown one - this
    # deliberately diverges from min_nodes'
    # fail-closed default.
    assert _question(None).is_storage_eligible_for("minikube") is True
    assert _question(None).is_storage_eligible_for("local-path") is True
    assert _question(None).is_storage_eligible_for(None) is True


def test_is_storage_eligible_for_unknown_active_profile_fails_closed_when_declared():
    # A question that DOES declare a requirement can never be confirmed
    # satisfied when doctor couldn't classify the cluster's default
    # StorageClass (active_profile=None means "unknown" here, distinct
    # from the question's own None meaning "no requirement").
    assert _question("minikube").is_storage_eligible_for(None) is False


def test_bank_with_no_storage_profile_set_is_unfiltered(question_bank_factory):
    # Matches set_node_count's existing "never called" behavior: a
    # QuestionBank that never had set_storage_profile() called returns
    # every discovered question regardless of storage_profile.
    bank = question_bank_factory(
        {"topic-a": ["easy", "easy"]}, storage_profile={"topic-a": ["minikube", "local-path"]}
    )
    assert len(bank.questions) == 2


def test_set_storage_profile_minikube_excludes_local_path_question(question_bank_factory):
    bank = question_bank_factory(
        {"topic-a": ["easy", "medium"]}, storage_profile={"topic-a": ["minikube", "local-path"]}
    )
    bank.set_storage_profile("minikube")
    ids = {q.id for q in bank.questions}
    assert ids == {"qT01-question"}
    assert bank.excluded_count == 1


def test_set_storage_profile_leaves_unconstrained_questions_visible_under_either_profile(
    question_bank_factory,
):
    bank = question_bank_factory(
        {"topic-a": ["easy", "medium", "hard"]},
        storage_profile={"topic-a": ["minikube", "local-path", None]},
    )
    bank.set_storage_profile("minikube")
    assert {q.id for q in bank.questions} == {"qT01-question", "qT03-question"}

    bank.set_storage_profile("local-path")
    assert {q.id for q in bank.questions} == {"qT02-question", "qT03-question"}


def test_set_storage_profile_unknown_excludes_every_declared_question(question_bank_factory):
    bank = question_bank_factory(
        {"topic-a": ["easy", "medium"]}, storage_profile={"topic-a": ["minikube", None]}
    )
    bank.set_storage_profile(None)
    assert {q.id for q in bank.questions} == {"qT02-question"}


def test_set_storage_profile_combines_with_node_count(question_bank_factory):
    # The two independent filters must both apply - a question failing either
    # one is excluded.
    bank = question_bank_factory(
        {"topic-a": ["easy", "medium"]},
        min_nodes={"topic-a": [1, 2]},
        storage_profile={"topic-a": "minikube"},
    )
    bank.set_node_count(1)
    bank.set_storage_profile("minikube")
    assert {q.id for q in bank.questions} == {"qT01-question"}

    bank.set_node_count(2)
    assert {q.id for q in bank.questions} == {"qT01-question", "qT02-question"}

    bank.set_storage_profile("local-path")
    assert bank.questions == []


def test_refresh_preserves_storage_profile(question_bank_factory):
    bank = question_bank_factory(
        {"topic-a": ["easy", "medium"]}, storage_profile={"topic-a": ["minikube", "local-path"]}
    )
    bank.set_storage_profile("minikube")
    bank.refresh()
    assert {q.id for q in bank.questions} == {"qT01-question"}


def test_real_bank_provisioner_specific_questions_are_gated_by_storage_profile():
    """Reads the actual questions/ directory to confirm the five shipped
    requirements.storage_profile: minikube questions are excluded under 'local-path' and included under
    'minikube', proving the real fragment entries are wired up correctly
    end to end - not just this file's synthetic fixtures."""
    expected_qids = {
        "q109-08-dynamic-provisioning-default-sc",
        "q109-09-custom-storageclass-provisioner",
        "q109-11-pvc-resize-allow-expansion",
        "q109-27-storageclass-waitforfirstconsumer",
        "q109-30-pvc-immutable-recreate-not-patch",
    }
    bank = QuestionBank(questions_dir=QUESTIONS_DIR)
    found = {q.id for q in bank.questions if q.storage_profile is not None}
    assert found == expected_qids
    for q in bank.questions:
        if q.id in expected_qids:
            assert q.storage_profile == "minikube"

    bank.set_storage_profile("local-path")
    remaining = {q.id for q in bank.questions}
    assert remaining.isdisjoint(expected_qids)

    bank.set_storage_profile("minikube")
    remaining = {q.id for q in bank.questions}
    assert expected_qids.issubset(remaining)
