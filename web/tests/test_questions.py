"""questions.discover_questions/QuestionBank against a real tmp_path fixture
tree (question_bank_factory, tests/conftest.py) - matches exactly what the
real questions/ directory looks like on disk, no mocking needed since this
is pure filesystem + yaml.safe_load, no subprocess."""
from __future__ import annotations

from pathlib import Path

from questions import QuestionBank, count_incomplete_question_dirs, discover_questions


def test_discovers_all_questions_across_topics(question_bank_factory):
    bank = question_bank_factory({"topic-a": 3, "topic-b": 2})
    assert len(bank) == 5
    assert set(bank.topics()) == {"topic-a", "topic-b"}
    assert bank.pool_size("topic-a") == 3
    assert bank.pool_size("topic-b") == 2


def test_question_ids_and_topics_are_correct(question_bank_factory):
    bank = question_bank_factory({"topic-a": 2})
    ids = {q.id for q in bank.questions}
    assert ids == {"qT01-question", "qT02-question"}
    assert all(q.topic == "topic-a" for q in bank.questions)


def test_fragment_metadata_is_attached(question_bank_factory):
    bank = question_bank_factory({"topic-a": 1})
    q = bank.get("qT01-question")
    assert q is not None
    assert q.domain == "topic-a domain"
    assert q.difficulty == "easy"
    assert q.points == 5
    assert q.resource_kinds == ["Pod"]


def test_folder_missing_check_sh_is_skipped(tmp_path):
    questions_dir = tmp_path / "questions"
    topic_dir = questions_dir / "topic-a"
    qdir = topic_dir / "qA01-incomplete"
    qdir.mkdir(parents=True)
    (qdir / "QUESTION.md").write_text("# incomplete\n")
    # No check.sh - discover_questions should skip this folder entirely,
    # not crash or half-include it (questions.py:130-133's guard).
    questions = discover_questions(questions_dir)
    assert questions == []


def test_folder_missing_question_md_is_skipped(tmp_path):
    questions_dir = tmp_path / "questions"
    qdir = questions_dir / "topic-a" / "qA01-incomplete"
    qdir.mkdir(parents=True)
    (qdir / "check.sh").write_text("#!/usr/bin/env bash\n")
    questions = discover_questions(questions_dir)
    assert questions == []


def test_count_incomplete_question_dirs_counts_what_discover_questions_skips(tmp_path):
    questions_dir = tmp_path / "questions"
    complete_dir = questions_dir / "topic-a" / "qA01-complete"
    complete_dir.mkdir(parents=True)
    (complete_dir / "QUESTION.md").write_text("# q\n")
    (complete_dir / "check.sh").write_text("#!/usr/bin/env bash\n")
    missing_check = questions_dir / "topic-a" / "qA02-missing-check"
    missing_check.mkdir(parents=True)
    (missing_check / "QUESTION.md").write_text("# q\n")
    missing_question_md = questions_dir / "topic-a" / "qA03-missing-question-md"
    missing_question_md.mkdir(parents=True)
    (missing_question_md / "check.sh").write_text("#!/usr/bin/env bash\n")

    assert count_incomplete_question_dirs(questions_dir) == 2
    assert len(discover_questions(questions_dir)) == 1


def test_count_incomplete_question_dirs_ignores_template_dir(tmp_path):
    questions_dir = tmp_path / "questions"
    qdir = questions_dir / "_template" / "qX01-example"
    qdir.mkdir(parents=True)
    (qdir / "QUESTION.md").write_text("# x\n")
    # Missing check.sh - would count as incomplete in a real topic, but
    # _template is scaffolding, not content, same as discover_questions.
    assert count_incomplete_question_dirs(questions_dir) == 0


def test_count_incomplete_question_dirs_on_missing_directory():
    assert count_incomplete_question_dirs(Path("/nonexistent/does-not-exist")) == 0


def test_template_dir_is_skipped(tmp_path):
    questions_dir = tmp_path / "questions"
    qdir = questions_dir / "_template" / "qX01-example"
    qdir.mkdir(parents=True)
    (qdir / "QUESTION.md").write_text("# x\n")
    (qdir / "check.sh").write_text("#!/usr/bin/env bash\n")
    questions = discover_questions(questions_dir)
    assert questions == []


def test_community_dir_is_a_real_discoverable_topic(question_bank_factory):
    # community/ (GPL-3.0 ported content, questions/community/README.md) is
    # a normal topic like any other, not scaffolding - see NON_TOPIC_DIRS's
    # docstring in questions.py. The real repo's community/ is empty today
    # (no question folders, just LICENSE+README.md), which already yields
    # zero Questions with no special-casing needed (discover_questions
    # skips any dir entry lacking QUESTION.md+check.sh regardless of topic
    # name) - this test exercises the populated case.
    bank = question_bank_factory({"community": 2})
    assert bank.topics() == ["community"]
    assert bank.pool_size("community") == 2
    assert all(q.topic == "community" for q in bank.questions)


def test_missing_questions_dir_returns_empty_list(tmp_path):
    bank = QuestionBank(questions_dir=tmp_path / "does-not-exist")
    assert len(bank) == 0
    assert bank.topics() == []


def test_bank_get_returns_none_for_unknown_id(question_bank_factory):
    bank = question_bank_factory({"topic-a": 1})
    assert bank.get("not-a-real-qid") is None


def test_refresh_picks_up_new_questions(tmp_path):
    questions_dir = tmp_path / "questions"
    qdir = questions_dir / "topic-a" / "qA01-first"
    qdir.mkdir(parents=True)
    (qdir / "QUESTION.md").write_text("# first\n")
    (qdir / "check.sh").write_text("#!/usr/bin/env bash\n")

    bank = QuestionBank(questions_dir=questions_dir)
    assert len(bank) == 1

    qdir2 = questions_dir / "topic-a" / "qA02-second"
    qdir2.mkdir(parents=True)
    (qdir2 / "QUESTION.md").write_text("# second\n")
    (qdir2 / "check.sh").write_text("#!/usr/bin/env bash\n")

    assert len(bank) == 1  # stale until refresh() is called
    bank.refresh()
    assert len(bank) == 2
