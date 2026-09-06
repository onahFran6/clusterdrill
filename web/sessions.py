"""The session layer on top of QuestionBank's flat question list.

There's a line between a topic's *pool* (every question that
exists under that topic) and a *session* (the ordered subset you actually
practice against, "typically 15-20"). This module is where that line gets
drawn concretely:

    - SESSION_SIZE: the exact number chosen for "typically 15-20" (see the
      constant's docstring for why).
    - start_fixed / start_randomized / start_mixed: build a concrete,
      ordered list of question ids for a new session.
    - ActiveSession / SessionStore: per-user, in-memory, server-side
      state holding whichever session is currently "active" for that
      user; no separate database needed.

This module never touches grading or reset - it only ever decides *which*
question ids are in play and in what order. Check/Reset (app.py) are
unaffected; they still operate on a single qid at a time.
"""
from __future__ import annotations

import random
import time
from dataclasses import dataclass, field
from typing import Literal, Optional

from questions import Question, QuestionBank

# "Typically 15-20." 15 is chosen, not 20 or a midpoint,
# for two reasons: (1) it matches the real CKAD exam's own format, "15-20
# performance-based tasks" at its low end, so a full session
# feels like a realistic exam-length rehearsal rather than an inflated
# drill; (2) it is low enough that most v1 topic pools (17-20 questions)
# sit strictly above it, so Randomized/Mixed unlock ("pool has more
# questions than the session size") without needing the
# pools to hit their ~50 ceiling first. Topics whose pool is at or below 15
# (state-persistence: 12, helm-crds: 12) simply get their whole pool in
# Fixed mode - see start_fixed's short-pool behavior below.
SESSION_SIZE = 15

# Revision, 2026-08-23: the timer used to be a
# per-session opt-in toggle. Direct product direction this session changed
# that: every session now starts its clock automatically, the same way a
# real lab (KodeKloud-style) starts a countdown the moment you begin, not
# something you have to remember to check a box for. A
# session now runs for a fixed duration and can be ended early via
# SessionStore.clear() (app.py's POST /sessions/end) - mirroring "start the
# lab, it runs for N minutes, end it when you're done."
#
# Two different default durations, not one flat number, because a
# single-topic Fixed/Randomized session and a full Mixed session are
# different rehearsals:
#   - MIXED_TIMER_SECONDS (120 min): a Mixed session's timer is
#     "effectively the 120-minute simulation" -
#     a direct textual match to the real exam's format ("2 hours,
#     15-20 tasks"), so Mixed keeps the real exam's own clock.
#   - TOPIC_TIMER_SECONDS (60 min): raised from the old 30-minute default
#     per direct request this session, to actually match "a lab session
#     lasts about an hour" rather than a tight speed-drill clock. Still
#     shorter than Mixed's full-exam simulation, since a single-topic
#     session (up to SESSION_SIZE questions) is a smaller scope than a
#     15-20 question mock exam.
TOPIC_TIMER_SECONDS = 60 * 60
MIXED_TIMER_SECONDS = 120 * 60

TOPIC_TIMER_MINUTES = TOPIC_TIMER_SECONDS // 60
MIXED_TIMER_MINUTES = MIXED_TIMER_SECONDS // 60

# Boss mini-exam. A short, fixed-size "fight" - 5
# questions, not the full 15-20 of a regular session - so its own clock is
# a tight speed-drill window, not a scaled-down TOPIC_TIMER_SECONDS. 15
# minutes for 5 questions works out to the same rough per-question budget
# as a Gold-tier clear on an easy/medium question with room to spare, per
# profile_store.py's speed-tier thresholds.
BOSS_SESSION_SIZE = 5
BOSS_TIMER_SECONDS = 15 * 60
BOSS_TIMER_MINUTES = BOSS_TIMER_SECONDS // 60

# HP is a flat, difficulty-agnostic damage model on purpose - the boss draw
# is already "mixed-difficulty" via BOSS_SESSION_SIZE questions sampled
# without a difficulty filter (see start_boss), so difficulty variance is
# baked into which 5 questions you get, not into how much a miss costs.
# A wrong Check costs enough that 4 misses ends the fight (out of 5
# questions, one clean pass is needed no matter what); a merely slow-but-
# correct pass (no speed tier earned, see profile_store._speed_tier_for)
# costs less - it's still forward progress, just not a flawless one - and
# five slow-but-correct passes alone (5 * 10 = 50) can never end a fight on
# their own, only wrong answers can.
BOSS_MAX_HP = 100
BOSS_DAMAGE_WRONG_CHECK = 25
BOSS_DAMAGE_SLOW_PASS = 10

# Daily/session mixed challenge - "a 5-question
# cross-topic draw (same mechanism as Mixed session mode) that refreshes
# each time you open the tool, its own small reward track separate from
# the topic labs." Same draw mechanism as start_mixed (below) but a
# smaller size and its own timer: longer than a boss fight's 15 minutes
# (there's no HP/damage pressure here, just a relaxed clear) but far
# short of a full Mixed/mock-exam run's 120 minutes, matching "quick daily
# task" rather than "exam rehearsal."
DAILY_SESSION_SIZE = 5
DAILY_TIMER_SECONDS = 20 * 60
DAILY_TIMER_MINUTES = DAILY_TIMER_SECONDS // 60

# True exam-condition mock exam. Unlike every other
# mode above, question count is a candidate choice, not a fixed constant -
# a preset list rather than free text for the same reason TIMER_CHOICES_
# MINUTES is a preset list (_resolve_exam_question_count stays in lock-step
# with the setup form's <select>, and a forged/out-of-range value can't do
# anything worse than "fall back to the default"). 15 is the default,
# matching SESSION_SIZE's own "typically 15-20" reasoning above.
EXAM_QUESTION_COUNT_CHOICES = [5, 10, 15, 20]
EXAM_DEFAULT_QUESTION_COUNT = 15

SessionMode = Literal["fixed", "randomized", "mixed", "boss", "daily", "exam"]
Difficulty = Literal["easy", "medium", "hard"]

# Practice-setup timer choices: a candidate
# picks one of these instead of always getting the mode's silent default.
# Bounded to a fixed preset list, not a free-text minute count - keeps the
# deadline math (_timer_fields) and the UI's <select> in lock-step, and
# rules out a mistyped "6000" minute session with no extra validation code.
TIMER_CHOICES_MINUTES = [15, 30, 45, 60, 90, 120]


def default_timer_seconds(mode: SessionMode) -> int:
    """Which default duration applies before the toggle is ever touched -
    see the constants' docstring above for the reasoning split."""
    if mode == "mixed":
        return MIXED_TIMER_SECONDS
    if mode == "boss":
        return BOSS_TIMER_SECONDS
    if mode == "daily":
        return DAILY_TIMER_SECONDS
    return TOPIC_TIMER_SECONDS


def _resolve_timer_seconds(mode: SessionMode, timer_minutes: Optional[int]) -> int:
    """timer_minutes is the candidate's explicit choice from the session-
    setup panel (TIMER_CHOICES_MINUTES) - None falls back to the mode's own
    silent default exactly as before this existed. Anything outside the
    known preset list is ignored rather than trusted verbatim (a stray/
    forged form value becomes "use the default", not an arbitrary clock),
    so this is the one place that needs to validate it."""
    if timer_minutes is not None and timer_minutes in TIMER_CHOICES_MINUTES:
        return timer_minutes * 60
    return default_timer_seconds(mode)


def _filter_by_difficulty(pool: list[Question], difficulty) -> list[Question]:
    """Shared by every start_* function - a no-op when difficulty is falsy
    (None, "", or an empty list), so existing callers that never pass it
    see identical behavior to before this existed.

    difficulty is either a single string (every pre-exam caller: Fixed/
    Randomized/Mixed's own single-select filter) or an iterable of strings
    (exam mode's multi-select difficulty mix) - accepting both
    here means exam mode reuses this exact function rather than needing
    its own near-duplicate filter.
    """
    if not difficulty:
        return pool
    allowed = {difficulty} if isinstance(difficulty, str) else set(difficulty)
    return [q for q in pool if q.difficulty in allowed]


def _exam_pool(bank: QuestionBank, topics: Optional[list[str]]) -> list[Question]:
    """The combined pool an exam draw samples from - every topic's pool
    combined (same as start_mixed) when topics is falsy (the setup form's
    "all topics" default), narrowed to just the chosen topics otherwise."""
    if not topics:
        return list(bank.questions)
    topic_set = set(topics)
    return [q for q in bank.questions if q.topic in topic_set]


def _resolve_exam_question_count(question_count: Optional[int]) -> int:
    """Same "unknown preset -> silent default" rule as
    _resolve_timer_seconds - a forged/out-of-range count can't do anything
    worse than falling back to EXAM_DEFAULT_QUESTION_COUNT."""
    if question_count is not None and question_count in EXAM_QUESTION_COUNT_CHOICES:
        return question_count
    return EXAM_DEFAULT_QUESTION_COUNT


def default_exam_timer_minutes(question_count: int) -> int:
    """PLAN.md §4.13: "defaults to whichever preset is closest to ~8
    minutes/question" - matching the real exam's own ~2 hours/15-20-tasks
    ratio. Picked from TIMER_CHOICES_MINUTES (the same preset list every
    other mode's timer select uses) rather than computed freely, so the
    default is always something the setup form's own <select> can actually
    represent."""
    target = question_count * 8
    return min(TIMER_CHOICES_MINUTES, key=lambda choice: abs(choice - target))


@dataclass
class ActiveSession:
    mode: SessionMode
    # topic is None for a Mixed session (it spans every topic); set for
    # Fixed/Randomized.
    topic: Optional[str]
    question_ids: list[str]
    started_at: float = field(default_factory=time.time)
    # Optional countdown. timer_enabled is the on/off toggle from
    # the session-start form; deadline is the *authoritative* wall-clock
    # unix timestamp the countdown counts down to, computed once here (server
    # side, at session-creation time) and never recomputed per page view -
    # this is what keeps a page refresh or Previous/Skip navigation from
    # resetting the countdown. The
    # frontend only ever reads this value; it never invents or extends it.
    # Both are None/False together whenever the toggle was off.
    timer_enabled: bool = False
    timer_duration_seconds: Optional[int] = None
    deadline: Optional[float] = None
    # In-memory only, tracking this live session for the
    # "clean-sweep" achievement (a full topic session with zero failed
    # Checks - clean iff failed_qids is empty) and a session-local combo
    # meter (consecutive first-try-correct Checks: a pass only extends the
    # combo if this qid has never failed a Check yet *this session*; any
    # failed Check resets the combo to zero). Ephemeral like
    # the rest of ActiveSession - the durable side-effect (the achievement
    # object) is written by profile_store the moment a condition is met, so
    # nothing here needs to survive a restart.
    passed_qids: set = field(default_factory=set)
    failed_qids: set = field(default_factory=set)
    combo: int = 0
    # Every qid this session has ever *viewed* (question_view.py's
    # question_context() adds to this on every view), regardless of
    # whether it's been graded yet - the question navigator's
    # "already looked at this one" marker, a strictly weaker condition
    # than passed_qids/failed_qids (a qid can be visited without ever
    # being Checked). Ephemeral like the rest of ActiveSession.
    visited_qids: set = field(default_factory=set)
    # Boss fight HP, meaningful only when mode == "boss" (every
    # other mode leaves this at its unused default). Damaged in
    # questions_router.check_question() on a failed or slow-but-correct
    # Check (see BOSS_DAMAGE_* above), clamped at 0 - never negative, and
    # never regenerates mid-fight.
    hp: int = BOSS_MAX_HP

    def index_of(self, qid: str) -> Optional[int]:
        try:
            return self.question_ids.index(qid)
        except ValueError:
            return None

    def __len__(self) -> int:
        return len(self.question_ids)


def topic_pool(bank: QuestionBank, topic: str) -> list[Question]:
    """All questions under one topic, in the bank's existing stable order."""
    return [q for q in bank.questions if q.topic == topic]


def mode_availability(pool_size: int) -> dict:
    """Which modes are offered for a pool of this size: "unlocks
    Randomized/Mixed once its pool has more questions than the session
    size."

    Fixed is always available (including pools smaller than SESSION_SIZE -
    it just becomes "the whole pool," see start_fixed). Randomized needs a
    strictly-larger-than-session-size pool of its own, taken literally -
    with pool == session size there is nothing left to
    leave out, so a "randomized subset" would just be a shuffle of the
    entire pool every time, which is a real mode but not what the rule
    above is describing as the gate. Mixed draws across every topic's pool at once
    (see start_mixed) so it is gated on the *combined* pool across all
    topics, not any single topic's pool - a small topic (e.g.
    state-persistence, 12) still contributes to a Mixed draw even though it
    can't run Randomized on its own.
    """
    return {
        "fixed": True,
        "randomized": pool_size > SESSION_SIZE,
    }


def _timer_fields(mode: SessionMode, timer_minutes: Optional[int] = None) -> dict:
    """Shared helper so all three start_* functions compute the deadline
    identically: once, here, at session-creation time - the one place the
    server-authoritative deadline gets stamped. Every session is timed now
    (see the revision note above) - there is no "off" branch anymore.
    timer_minutes is the candidate's explicit choice (see
    _resolve_timer_seconds); omitted/invalid falls back to the mode's own
    silent default exactly as before the session-setup panel existed."""
    duration = _resolve_timer_seconds(mode, timer_minutes)
    return {
        "timer_enabled": True,
        "timer_duration_seconds": duration,
        "deadline": time.time() + duration,
    }


def start_fixed(
    bank: QuestionBank, topic: str, difficulty: Optional[str] = None, timer_minutes: Optional[int] = None,
) -> ActiveSession:
    """Deterministic: the topic's first N questions in the bank's existing
    (alphabetical-by-folder-name, i.e. numeric) order. Reproducible run to
    run because it never calls random - same topic, same pool on disk,
    same result every time.

    If the topic's pool (after an optional difficulty filter) has
    SESSION_SIZE questions or fewer, Fixed is just the whole filtered pool
    in order (e.g. state-persistence's 12 questions all show up, not
    12-of-15-that-don't-exist) - same graceful "take what's there" behavior
    a difficulty filter gets for free, no separate small-pool branch needed.
    """
    pool = _filter_by_difficulty(topic_pool(bank, topic), difficulty)
    chosen = pool[:SESSION_SIZE]
    return ActiveSession(
        mode="fixed",
        topic=topic,
        question_ids=[q.id for q in chosen],
        **_timer_fields("fixed", timer_minutes),
    )


def start_randomized(
    bank: QuestionBank, topic: str, difficulty: Optional[str] = None, timer_minutes: Optional[int] = None,
) -> ActiveSession:
    """A freshly shuffled N-question subset of one topic's pool (after an
    optional difficulty filter). Reshuffled every time a new session is
    started (not persisted/seeded), so repeat practice on the same topic
    doesn't mean memorizing the same order or even the same subset once the
    (filtered) pool exceeds SESSION_SIZE.
    """
    pool = _filter_by_difficulty(topic_pool(bank, topic), difficulty)
    ids = [q.id for q in pool]
    random.shuffle(ids)
    chosen = ids[:SESSION_SIZE]
    return ActiveSession(
        mode="randomized",
        topic=topic,
        question_ids=chosen,
        **_timer_fields("randomized", timer_minutes),
    )


def start_mixed(
    bank: QuestionBank, difficulty: Optional[str] = None, timer_minutes: Optional[int] = None,
) -> ActiveSession:
    """A shuffled N-question draw across every topic's pool combined (after
    an optional difficulty filter) - a mock-exam-style mix. topic=None on
    the resulting session since it isn't
    scoped to one topic.
    """
    ids = [q.id for q in _filter_by_difficulty(bank.questions, difficulty)]
    random.shuffle(ids)
    chosen = ids[:SESSION_SIZE]
    return ActiveSession(
        mode="mixed",
        topic=None,
        question_ids=chosen,
        **_timer_fields("mixed", timer_minutes),
    )


def start_exam(
    bank: QuestionBank,
    topics: Optional[list[str]] = None,
    difficulties: Optional[list[str]] = None,
    question_count: Optional[int] = None,
    timer_minutes: Optional[int] = None,
) -> ActiveSession:
    """The true exam-condition mock exam - a
    shuffled draw across the candidate's chosen topics (default: every
    topic, same combined pool as start_mixed) and difficulty mix (default:
    all three), sized to one of EXAM_QUESTION_COUNT_CHOICES rather than the
    fixed SESSION_SIZE every other mode uses. topic=None on the resulting
    session, same as start_mixed/start_daily, since it isn't scoped to one
    topic even when the candidate narrowed to a handful.

    Deliberately does not use _timer_fields: every other mode's timer
    defaults to one fixed constant regardless of what else the candidate
    picked, but exam mode's default depends on question_count (see
    default_exam_timer_minutes) - there is no single "the" default to
    look up by mode name alone.

    This function only ever builds the ActiveSession - the no-live-
    feedback/free-navigation/submit-to-grade behavior is everything
    *outside* this function (question.html, questions_router.py,
    routers/sessions_router.py's submit_exam()), not here.
    """
    pool = _filter_by_difficulty(_exam_pool(bank, topics), difficulties)
    ids = [q.id for q in pool]
    random.shuffle(ids)
    count = _resolve_exam_question_count(question_count)
    chosen = ids[:count]
    resolved_timer_minutes = (
        timer_minutes if timer_minutes in TIMER_CHOICES_MINUTES else default_exam_timer_minutes(count)
    )
    duration = resolved_timer_minutes * 60
    return ActiveSession(
        mode="exam",
        topic=None,
        question_ids=chosen,
        timer_enabled=True,
        timer_duration_seconds=duration,
        deadline=time.time() + duration,
    )


def start_boss(bank: QuestionBank, topic: str) -> ActiveSession:
    """A boss mini-exam - a shuffled BOSS_SESSION_SIZE-question draw
    from one topic's pool, no difficulty filter (the pool itself already
    spans easy/medium/hard, which is what makes the draw "mixed-difficulty"
    - see BOSS_MAX_HP's docstring). Unlike start_fixed/start_randomized,
    there's no difficulty/timer_minutes override here: a boss fight always
    runs at BOSS_TIMER_SECONDS, on the full pool, the same fixed "fight"
    every time you challenge a given topic's boss - callers are expected to
    have already checked the fight is unlocked (profile_store.boss_unlocked)
    before calling this.
    """
    ids = [q.id for q in topic_pool(bank, topic)]
    random.shuffle(ids)
    chosen = ids[:BOSS_SESSION_SIZE]
    return ActiveSession(
        mode="boss",
        topic=topic,
        question_ids=chosen,
        timer_enabled=True,
        timer_duration_seconds=BOSS_TIMER_SECONDS,
        deadline=time.time() + BOSS_TIMER_SECONDS,
        hp=BOSS_MAX_HP,
    )


def start_daily(bank: QuestionBank) -> ActiveSession:
    """The daily/session mixed challenge - a fresh shuffled
    DAILY_SESSION_SIZE-question draw across every topic's pool combined,
    the exact same mechanism as start_mixed above (no difficulty filter -
    this is deliberately not offered as a choice here, unlike Mixed's own
    session-setup panel - this is meant to be a lightweight, no-
    configuration "open the tool, get 5 questions" flow), just a smaller
    size and its own shorter timer. topic=None like start_mixed - it also
    spans every topic.
    """
    ids = [q.id for q in bank.questions]
    random.shuffle(ids)
    chosen = ids[:DAILY_SESSION_SIZE]
    return ActiveSession(
        mode="daily",
        topic=None,
        question_ids=chosen,
        timer_enabled=True,
        timer_duration_seconds=DAILY_TIMER_SECONDS,
        deadline=time.time() + DAILY_TIMER_SECONDS,
    )


class SessionStore:
    """Holds each user's active session, if any. In-memory, server-side -
    deliberately not backed by a database. Restarting the web process
    clears it, which is fine: there is nothing here that needs to survive a
    restart any more than QuestionBank's own in-memory state does.

    Used to be a single `Optional
    [ActiveSession]` slot, from an original single-active-user
    design - now keyed by user_id, so two logged-in accounts each get their
    own active session instead of one clobbering the other's "next
    question" click. user_id=None (the password gate off / no-accounts
    case) reproduces the exact prior single-slot behavior - every caller in
    that mode shares that one key, same as before this change.
    """

    def __init__(self) -> None:
        self._active: dict[Optional[str], ActiveSession] = {}

    def get(self, user_id: Optional[str] = None) -> Optional[ActiveSession]:
        return self._active.get(user_id)

    def set_active(self, session: ActiveSession, user_id: Optional[str] = None) -> None:
        self._active[user_id] = session

    def clear(self, user_id: Optional[str] = None) -> None:
        self._active.pop(user_id, None)

    def clear_all(self) -> None:
        """Every user's active session at once - used by the idle watchdog
        (app.py), which still degrades access for everyone together;
        a per-user terminal/idle clock is a known follow-on refinement,
        not implemented yet."""
        self._active.clear()


# Module-level singleton - this *is* the "simple module-level object" the
# ticket calls for. app.py imports this instance directly.
store = SessionStore()


@dataclass
class ExamResult:
    """One exam's submit-and-score result - the
    per-question pass/fail detail the results view needs, which
    profile_store.record_exam_attempt() deliberately doesn't persist (it
    only keeps the aggregate score/total/duration/domain-breakdown, same
    as every other examAttempts entry). This is why this lives here as
    its own short-lived, in-memory record rather than being read back off
    the profile - it's the *this-attempt* detail, not durable history."""

    score: int
    total: int
    duration_sec: int
    domain_breakdown: dict[str, int]
    questions: list[dict]  # [{"id": qid, "domain": ..., "passed": bool}, ...]


class ExamResultStore:
    """Same in-memory, per-user, restart-clears-it shape as SessionStore
    above - overwritten by the next exam's submission, never durable.
    Deliberately a separate store, not folded into ActiveSession itself:
    routers/sessions_router.py's submit_exam() already clears the
    ActiveSession the moment it finishes grading (same cleanup end_session
    does), but the result still needs to survive one more request (the
    redirect to GET /sessions/results) after that."""

    def __init__(self) -> None:
        self._results: dict[Optional[str], ExamResult] = {}

    def get(self, user_id: Optional[str] = None) -> Optional[ExamResult]:
        return self._results.get(user_id)

    def set(self, result: ExamResult, user_id: Optional[str] = None) -> None:
        self._results[user_id] = result

    def clear_all(self) -> None:
        """Every user's stored result at once - test isolation only (see
        tests/routes/conftest.py); nothing in the app itself calls this."""
        self._results.clear()


exam_result_store = ExamResultStore()
