"""Shared fixtures for practice-bank/web's test suite.

Two things live here that every other test file depends on:

1. A hard, autouse safety net against real `tmux`/`ttyd`/`kubectl` calls.
   Context: during manual (non-pytest) live-fire testing of the idle-kill
   watchdog this session, a shortened-timer test run against the real app
   killed two pre-existing, real tmux sessions on the developer's machine
   (`clusterdrill-1`/`clusterdrill-2`) - dormant, but real. That happened
   outside pytest, but the risk is identical here: several code paths under
   test (ttyd_manager.py, profile_store.py) shell out to tmux/ttyd/kubectl
   for real if a test forgets to mock `subprocess.run`/`Popen`. This fixture
   makes that failure mode impossible instead of relying on every test
   author remembering to mock correctly - it's a guardrail, not a
   convention.

2. A `question_bank_factory` fixture building a small, realistic on-disk
   question tree under `tmp_path`, matching exactly what
   `questions.discover_questions()` expects (QUESTION.md + check.sh per
   question folder, optional domains.fragment.yaml) - reused by
   test_questions.py and test_sessions.py rather than each hand-rolling a
   different fake bank shape.
"""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

import pytest
import yaml

# tests/ has no __init__.py (flat pytest rootdir-insertion style, matching
# this app's own flat `import auth` / `from questions import ...` module
# layout rather than a package) - so callers of `pytest` from outside
# practice-bank/web/ still resolve `import questions` etc. correctly.
WEB_DIR = Path(__file__).resolve().parent.parent
if str(WEB_DIR) not in sys.path:
    sys.path.insert(0, str(WEB_DIR))

_FORBIDDEN_BINARIES = {"tmux", "ttyd", "kubectl"}


def _binary_name(arg) -> str:
    return str(arg).rsplit("/", 1)[-1]


def _check_argv(args) -> None:
    if not isinstance(args, (list, tuple)) or not args:
        return
    first = _binary_name(args[0])
    if first in _FORBIDDEN_BINARIES:
        raise RuntimeError(
            f"Test attempted a REAL subprocess call to {first!r} "
            f"(argv={list(args)!r}). tmux/ttyd/kubectl must always be "
            "mocked in tests - see this fixture's docstring for why."
        )


@pytest.fixture(autouse=True)
def _forbid_real_tmux_ttyd_kubectl(monkeypatch):
    """Autouse: applies to every test in the suite with no opt-in required.
    A test that wants to assert *how* subprocess.run/Popen would have been
    called (e.g. ttyd_manager.kill_all_tmux_sessions' argv shape) should
    replace subprocess.run/Popen with its own mock inside the test body -
    that replacement simply shadows this guard for that test (a MagicMock
    never shells out for real either way), so there's no conflict."""
    real_run = subprocess.run

    def guarded_run(args, *a, **kw):
        _check_argv(args)
        return real_run(args, *a, **kw)

    real_popen_init = subprocess.Popen.__init__

    def guarded_popen_init(self, args, *a, **kw):
        _check_argv(args)
        real_popen_init(self, args, *a, **kw)

    monkeypatch.setattr(subprocess, "run", guarded_run)
    monkeypatch.setattr(subprocess.Popen, "__init__", guarded_popen_init)


@pytest.fixture
def question_bank_factory(tmp_path):
    """Returns a builder: build(topic_sizes: dict[str, int | list[str]]) ->
    QuestionBank, e.g. build({"topic-a": 3, "topic-b": 20}) - the second
    topic exceeds sessions.SESSION_SIZE (15), useful for testing
    Randomized-mode unlock (sessions.mode_availability) without every test
    paying that cost.

    A topic's value can also be a list of difficulty strings instead of a
    plain count (e.g. ["easy", "easy", "medium", "hard"]) when a test needs
    control over the difficulty mix - see test_sessions.py's difficulty-
    filter tests. A plain int is shorthand for "that many 'easy' questions",
    unchanged from before this existed.

    An optional `min_nodes` kwarg controls each question's
    `requirements.min_nodes` fragment field. Per topic, the
    value is either a single int (every question in that topic gets that
    min_nodes) or a list the same length as that topic's difficulties
    (per-question values; `None` in the list omits the `requirements` key
    entirely for that one question, matching the pre-existing default).
    Topics absent from `min_nodes` keep the old default of no `requirements`
    key at all - existing callers that never pass this kwarg see no change.

    An optional `storage_profile` kwarg works the same way, one level down,
    for `requirements.storage_profile`. A topic's
    value is either a single string/None (every question in that topic gets
    that storage_profile) or a per-question list. Combines with `min_nodes`
    into the same `requirements` dict when both are given for the same
    question.
    """
    from questions import QuestionBank

    def build(
        topic_sizes: dict[str, "int | list[str]"],
        min_nodes: "dict[str, int | list[int | None]] | None" = None,
        storage_profile: "dict[str, str | list[str | None]] | None" = None,
    ):
        min_nodes = min_nodes or {}
        storage_profile = storage_profile or {}
        questions_dir = tmp_path / f"questions-{id(topic_sizes)}"
        for topic, spec in topic_sizes.items():
            difficulties = ["easy"] * spec if isinstance(spec, int) else list(spec)
            topic_min_nodes = min_nodes.get(topic)
            if isinstance(topic_min_nodes, int):
                topic_min_nodes = [topic_min_nodes] * len(difficulties)
            topic_storage_profile = storage_profile.get(topic)
            if topic_storage_profile is None or isinstance(topic_storage_profile, str):
                topic_storage_profile = [topic_storage_profile] * len(difficulties)
            topic_dir = questions_dir / topic
            topic_dir.mkdir(parents=True)
            fragment_entries = []
            for i, difficulty in enumerate(difficulties, start=1):
                qid = f"q{topic[:1].upper()}{i:02d}-question"
                qdir = topic_dir / qid
                qdir.mkdir()
                (qdir / "QUESTION.md").write_text(f"# {qid}\n\nDo the thing.\n")
                (qdir / "check.sh").write_text(
                    "#!/usr/bin/env bash\necho 'SCORE: 0/0'\n"
                )
                entry = {
                    "id": qid,
                    "domain": f"{topic} domain",
                    "difficulty": difficulty,
                    "resource_kinds": ["Pod"],
                    "points": 5,
                }
                question_min_nodes = (
                    topic_min_nodes[i - 1] if topic_min_nodes is not None else None
                )
                question_storage_profile = topic_storage_profile[i - 1]
                requirements = {}
                if question_min_nodes is not None:
                    requirements["min_nodes"] = question_min_nodes
                if question_storage_profile is not None:
                    requirements["storage_profile"] = question_storage_profile
                if requirements:
                    entry["requirements"] = requirements
                fragment_entries.append(entry)
            (topic_dir / "domains.fragment.yaml").write_text(
                yaml.safe_dump({"questions": fragment_entries})
            )
        return QuestionBank(questions_dir=questions_dir)

    return build


@pytest.fixture
def fake_bank(question_bank_factory):
    """The common case: a couple of small topics, no mode-unlock edge cases."""
    return question_bank_factory({"topic-a": 3, "topic-b": 1})
