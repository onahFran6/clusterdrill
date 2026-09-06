"""Question discovery for the web app.

Reads the folder schema documented in practice-bank/questions/README.md
 directly from disk:

    questions/<topic>/qNNN-slug/{QUESTION.md,setup.sh,check.sh,ANSWER.md}
    questions/<topic>/domains.fragment.yaml   (metadata: domain, difficulty,
                                                resource_kinds, points)

We do not shell out to lib/load-domains.sh at request time - we read the
same domains.fragment.yaml files it reads, directly, so the web app has no
hard dependency on that script having been run first (it may not have been,
e.g. a topic still authoring content with no fragment yet). Where a fragment
entry is missing for a question folder that otherwise looks valid (has
QUESTION.md + check.sh), the question is still discovered with metadata
defaults - only the schema needs to be wired up here, not strict validation.

This module never touches lib/*, never writes into questions/*, and never
calls setup.sh/check.sh itself - callers (app.py) own subprocess execution.
"""
from __future__ import annotations

import logging
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

import yaml

logger = logging.getLogger("clusterdrill.questions")

BANK_ROOT = Path(__file__).resolve().parent.parent
QUESTIONS_DIR = BANK_ROOT / "questions"
LIB_DIR = BANK_ROOT / "lib"

# Folders under questions/ that are not topics (scaffolding, not content).
# "community" (GPL-3.0 ported content, questions/community/README.md) is
# deliberately NOT here - it's a real, discoverable topic like any other
#. It's just currently empty (only LICENSE + README.md, no question
# folders yet) - discover_questions below already skips anything under a
# topic dir that isn't a real question folder, so an empty community/
# naturally yields zero questions and doesn't need special-casing here.
NON_TOPIC_DIRS = {"_template"}

# Sentinel distinguishing "QuestionBank.set_storage_profile was never
# called" from the real value None ("active storage profile is unknown") -
# see QuestionBank.__init__'s docstring comment.
_UNSET = object()


@dataclass
class Question:
    id: str  # matches folder name, e.g. "q101-01-create-pod-imperative"
    topic: str  # e.g. "imperative-commands"
    path: Path
    domain: Optional[str] = None
    difficulty: Optional[str] = None
    resource_kinds: list = field(default_factory=list)
    points: Optional[int] = None
    min_nodes: Optional[int] = None
    storage_profile: Optional[str] = None  # None => provisioner-agnostic, any active profile OK

    def is_eligible_for(self, node_count: int) -> bool:
        """Whether this question may run on a cluster of ``node_count`` nodes.

        Missing or malformed metadata fails closed once the appliance has a
        known topology. This prevents a newly added, unaudited question from
        accidentally becoming available on a one-node local cluster.
        """
        return (
            isinstance(self.min_nodes, int)
            and not isinstance(self.min_nodes, bool)
            and self.min_nodes >= 1
            and self.min_nodes <= node_count
        )

    def is_storage_eligible_for(self, active_profile: Optional[str]) -> bool:
        """Whether this question may run under the cluster's active storage
        profile.

        Unlike is_eligible_for's min_nodes check, a missing storage_profile
        means "no constraint" rather than fail-closed - only 5 of ~500
        questions in the whole bank need a specific provisioner, so
        defaulting to fail-closed would silently exclude everything else
        the moment an operator ever runs a non-default profile. An
        *unknown* active_profile (doctor could not classify the default
        StorageClass) still fails closed for any question that does
        declare a requirement, since no declared profile can be confirmed
        satisfied.
        """
        if self.storage_profile is None:
            return True
        return active_profile is not None and self.storage_profile == active_profile

    @property
    def question_md(self) -> Path:
        return self.path / "QUESTION.md"

    @property
    def answer_md(self) -> Path:
        return self.path / "ANSWER.md"

    @property
    def check_sh(self) -> Path:
        return self.path / "check.sh"

    @property
    def setup_sh(self) -> Path:
        return self.path / "setup.sh"

    @property
    def diagram_mmd(self) -> Path:
        """Per-question generated Mermaid diagram - a sibling of
        QUESTION.md/ANSWER.md inside this question's own folder. Distinct
        from the topic-level primer at questions/<topic>/diagram.mmd (see
        QuestionBank.topic_diagram_mmd) - same filename, different level."""
        return self.path / "diagram.mmd"

    @property
    def diagram_json(self) -> Path:
        """Diagram tab rebuild: the same generator (generate_diagram.py)
        writes this alongside diagram.mmd - structured architecture+sequence
        data for the new SVG renderer (static/diagram.js), with diagram_mmd
        kept as app.py's fallback if this is ever missing/malformed."""
        return self.path / "diagram.json"


def _load_fragment_metadata(topic_dir: Path) -> dict:
    """Read questions/<topic>/domains.fragment.yaml -> {qid: {domain,...}}.

    Returns {} if the fragment doesn't exist yet (e.g. content authoring in
    progress) - discovery still works from the folders alone; this is a
    schema reader, not a completeness check on the content bank.
    """
    fragment_path = topic_dir / "domains.fragment.yaml"
    if not fragment_path.exists():
        return {}
    try:
        raw = yaml.safe_load(fragment_path.read_text()) or {}
    except yaml.YAMLError as exc:
        logger.warning("skipping malformed fragment %s: %s", fragment_path, exc)
        return {}

    by_id = {}
    for entry in raw.get("questions", []) or []:
        qid = entry.get("id")
        if qid:
            by_id[qid] = entry
    return by_id


def discover_questions(questions_dir: Path = QUESTIONS_DIR) -> list[Question]:
    """Walk questions/<topic>/qNNN-slug/ and return Question objects.

    Order is simple and hardcoded for now: topics sorted
    alphabetically, questions within a topic sorted alphabetically by folder
    name (which is id-prefixed, e.g. q101-01, q101-02, ... so this also
    happens to be numeric order for the existing content).
    """
    questions: list[Question] = []
    if not questions_dir.is_dir():
        return questions

    for topic_dir in sorted(questions_dir.iterdir()):
        if not topic_dir.is_dir() or topic_dir.name in NON_TOPIC_DIRS:
            continue
        if topic_dir.name.startswith("."):
            continue

        fragment_meta = _load_fragment_metadata(topic_dir)

        for q_dir in sorted(topic_dir.iterdir()):
            if not q_dir.is_dir():
                continue
            question_md = q_dir / "QUESTION.md"
            check_sh = q_dir / "check.sh"
            if not question_md.exists() or not check_sh.exists():
                # Not a real question folder (e.g. leftover scaffolding).
                continue

            meta = fragment_meta.get(q_dir.name, {})
            questions.append(
                Question(
                    id=q_dir.name,
                    topic=topic_dir.name,
                    path=q_dir,
                    domain=meta.get("domain"),
                    difficulty=meta.get("difficulty"),
                    resource_kinds=meta.get("resource_kinds", []) or [],
                    points=meta.get("points"),
                    min_nodes=(meta.get("requirements") or {}).get("min_nodes"),
                    storage_profile=(meta.get("requirements") or {}).get("storage_profile"),
                )
            )

    return questions


def count_incomplete_question_dirs(questions_dir: Path = QUESTIONS_DIR) -> int:
    """Count question-shaped folders discover_questions silently skips for
    missing QUESTION.md/check.sh (content mid-authoring, or leftover
    scaffolding) - mirrors discover_questions' own skip condition exactly,
    kept alongside it so the two can't drift apart. Surfaced in
    `clusterdrill local doctor` instead of staying invisible."""
    count = 0
    if not questions_dir.is_dir():
        return count
    for topic_dir in questions_dir.iterdir():
        if not topic_dir.is_dir() or topic_dir.name in NON_TOPIC_DIRS or topic_dir.name.startswith("."):
            continue
        for q_dir in topic_dir.iterdir():
            if not q_dir.is_dir():
                continue
            if not (q_dir / "QUESTION.md").exists() or not (q_dir / "check.sh").exists():
                count += 1
    return count


class QuestionBank:
    """In-memory, re-scanned-on-demand view of the questions/ directory.

    Kept intentionally simple - no session/randomization layer here, see
    sessions.py for that.
    """

    def __init__(self, questions_dir: Path = QUESTIONS_DIR):
        self.questions_dir = questions_dir
        self._questions: list[Question] = []
        self._node_count: Optional[int] = None
        # _UNSET, not None: None is a real, meaningful value here, distinct from "set_storage_profile was never called at
        # all" (e.g. every bare QuestionBank() test fixture), which must
        # keep skipping storage filtering entirely, the same way
        # _node_count's own None-means-unset sentinel already works.
        self._storage_profile: object = _UNSET
        self.refresh()

    def refresh(self) -> None:
        self._questions = discover_questions(self.questions_dir)

    @property
    def questions(self) -> list[Question]:
        questions = self._questions
        if self._node_count is not None:
            questions = [q for q in questions if q.is_eligible_for(self._node_count)]
        if self._storage_profile is not _UNSET:
            questions = [q for q in questions if q.is_storage_eligible_for(self._storage_profile)]
        return questions

    @property
    def excluded_count(self) -> int:
        return len(self._questions) - len(self.questions)

    def set_node_count(self, node_count: int) -> None:
        """Set the server-derived topology used by every public bank view."""
        self._node_count = max(0, node_count)

    def set_storage_profile(self, storage_profile: Optional[str]) -> None:
        """Set the server-derived active storage profile ("minikube",
        "local-path", or None for unknown) used by every public bank view -
        see Question.is_storage_eligible_for for the None/unknown
        distinction."""
        self._storage_profile = storage_profile

    def __len__(self) -> int:
        return len(self.questions)

    def get(self, qid: str) -> Optional[Question]:
        for q in self.questions:
            if q.id == qid:
                return q
        return None

    def index_of(self, qid: str) -> Optional[int]:
        for i, q in enumerate(self.questions):
            if q.id == qid:
                return i
        return None

    def first(self) -> Optional[Question]:
        return self.questions[0] if self.questions else None

    def at(self, index: int) -> Optional[Question]:
        questions = self.questions
        if 0 <= index < len(questions):
            return questions[index]
        return None

    def topics(self) -> list[str]:
        """Distinct topic names, in the same stable (alphabetical) order
        discover_questions already walks them in - used by the topic-lab
        landing page."""
        seen: list[str] = []
        for q in self.questions:
            if q.topic not in seen:
                seen.append(q.topic)
        return seen

    def pool_size(self, topic: str) -> int:
        return sum(1 for q in self.questions if q.topic == topic)

    def topic_diagram_mmd(self, topic: str) -> Path:
        """Hand-authored topic-level primer diagram, e.g.
        questions/services-networking/diagram.mmd - a sibling of the topic
        directory's per-question subfolders, not inside any of them. This
        is a plain path join (no discovery needed - one fixed filename per
        topic directory), kept as a QuestionBank method so app.py doesn't
        need to know the on-disk layout directly, matching how question_md/
        answer_md are reached via Question properties rather than raw path
        joins in app.py."""
        return self.questions_dir / topic / "diagram.mmd"

    def topic_diagram_json(self, topic: str) -> Path:
        """Diagram tab rebuild: the hand-converted architecture-only JSON
        sibling of topic_diagram_mmd() above (topic primers have no Sequence
        view - see the rebuild plan for why)."""
        return self.questions_dir / topic / "diagram.json"


# Module-level singleton - matches every other stateful concern in this app
# (sessions.store, idle.tracker, ttyd_manager.manager): one shared bank
# instance, imported directly by routers/services rather than passed around.
# Was previously instantiated in app.py; moved here so it lives with the
# class it's an instance of, like everything else.
bank = QuestionBank()
