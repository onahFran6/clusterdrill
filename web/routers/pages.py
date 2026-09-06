"""Hub page routes - extracted from app.py's original monolith (2026-08
restructure) with no behavior change, just a new home: `/`, `/topics`,
`/topics/{topic}`, `/practice-tests`, `/progress`, `/mock-exam`.
"""
from __future__ import annotations

from datetime import datetime, timedelta, timezone

import auth
import profile_store
from fastapi import APIRouter, HTTPException
from fastapi.responses import RedirectResponse
from services.question_view import base_context, topic_progress_pct
from sessions import (
    BOSS_SESSION_SIZE,
    BOSS_TIMER_MINUTES,
    DAILY_SESSION_SIZE,
    DAILY_TIMER_MINUTES,
    EXAM_DEFAULT_QUESTION_COUNT,
    EXAM_QUESTION_COUNT_CHOICES,
    MIXED_TIMER_SECONDS,
    SESSION_SIZE,
    TIMER_CHOICES_MINUTES,
    TOPIC_TIMER_SECONDS,
    default_exam_timer_minutes,
    exam_result_store,
    mode_availability,
)
from sessions import (
    store as session_store,
)
from starlette.requests import Request
from templating import templates

from questions import bank

router = APIRouter()


@router.get("/")
def index():
    """Landing behavior: the flat "redirect to the first question
    in the bank" behavior is replaced by the topic-lab landing
    page - starting a session is now the entry point, not stumbling into
    question #1 of 173 with no session context at all.
    """
    return RedirectResponse(url="/topics")


@router.get("/topics")
def list_topics(request: Request):
    """Topic-lab landing/start page: every topic with its
    pool size and which session modes are available for it.
    """
    bank.refresh()
    user_id = auth.current_user_id(request.session)
    profile = profile_store.get_profile(user_id)
    topics = []
    for topic in bank.topics():
        pool_size = bank.pool_size(topic)
        availability = mode_availability(pool_size)
        topic_qids = [q.id for q in bank.questions if q.topic == topic]
        topics.append(
            {
                "name": topic,
                "pool_size": pool_size,
                "fixed_available": availability["fixed"],
                "randomized_available": availability["randomized"],
                # Mixed is gated on the combined pool across every topic,
                # not this topic's own pool - see sessions.mode_availability
                # and start_mixed. With 173 questions total this is always
                # true today, but it's computed rather than hardcoded so a
                # from-scratch/dev bank with a handful of stub questions
                # doesn't offer a Mixed draw it can't actually fill.
                "mixed_available": len(bank) > SESSION_SIZE,
                "session_size": min(pool_size, SESSION_SIZE),
                # Real progress, not a placeholder - see
                # topic_progress_pct() above.
                "progress_pct": topic_progress_pct(profile.spec, topic_qids),
            }
        )

    active = session_store.get(user_id)
    # Today's daily-challenge reward state - see profile_store.
    # apply_daily_challenge_clear's docstring for why the achievement name
    # is keyed on the date, not on any particular session's question ids.
    today = datetime.now(timezone.utc).date().isoformat()
    daily_cleared_today = profile_store.has_achievement(f"daily-challenge-{today}", user_id=user_id)

    return templates.TemplateResponse(
        request,
        "topics.html",
        {
            **base_context(request),
            "active_nav": "topics",
            "topics": topics,
            "session_size": SESSION_SIZE,
            "total_pool": len(bank),
            "active_session": active,
            # Every session is timed automatically now (see sessions.py's
            # revision note) - these are shown as plain info, not a
            # checkbox toggle anymore, so the candidate knows which clock
            # they're getting before they click a mode button.
            "topic_timer_minutes": TOPIC_TIMER_SECONDS // 60,
            "mixed_timer_minutes": MIXED_TIMER_SECONDS // 60,
            "daily_session_size": min(len(bank), DAILY_SESSION_SIZE),
            "daily_timer_minutes": DAILY_TIMER_MINUTES,
            "daily_cleared_today": daily_cleared_today,
        },
    )


@router.get("/topics/{topic}")
def topic_detail(request: Request, topic: str, filter: str = "all", difficulty: str = "all"):
    """Per-topic question list with real pass/fail/unanswered
    state read from the stored profile - a net-new browsing capability (v1 only
    ever let you start a timed session, never look at individual past
    results). Each row links straight to that question's own page
    (view_question already supports viewing any qid standalone outside an
    active session) - useful for reviewing or
    retrying one specific question without starting a whole new session.

    Two independent filters over the same row list, both AND-combined:
    `filter` (status: all/unanswered/correct/incorrect, unchanged) and the
    new `difficulty` (all/easy/medium/hard). difficulty doubles as the
    session-setup panel's pre-selected value below - browsing "Hard" and
    then hitting Start Practice defaults to a hard-only session, so the two
    read as one connected choice instead of unrelated controls that happen
    to share a word.
    """
    bank.refresh()
    if topic not in bank.topics():
        raise HTTPException(status_code=404, detail=f"unknown topic '{topic}'")
    if filter not in ("all", "unanswered", "correct", "incorrect"):
        filter = "all"
    if difficulty not in ("all", "easy", "medium", "hard"):
        difficulty = "all"

    profile = profile_store.get_profile(auth.current_user_id(request.session))
    questions_status = profile.spec.get("questions", {})
    topic_questions = [q for q in bank.questions if q.topic == topic]

    rows = []
    counts = {"all": 0, "unanswered": 0, "correct": 0, "incorrect": 0}
    difficulty_counts = {"all": 0, "easy": 0, "medium": 0, "hard": 0}
    for q in topic_questions:
        entry = questions_status.get(q.id)
        if entry is None:
            status = "unanswered"
        elif entry.get("passed"):
            status = "correct"
        else:
            status = "incorrect"
        counts["all"] += 1
        counts[status] += 1
        difficulty_counts["all"] += 1
        if q.difficulty in difficulty_counts:
            difficulty_counts[q.difficulty] += 1
        rows.append({
            "id": q.id,
            "domain": q.domain,
            "difficulty": q.difficulty,
            "status": status,
            "best_time_ms": entry.get("bestTimeMs") if entry else None,
            "best_speed_tier": entry.get("bestSpeedTier") if entry else None,
        })

    if filter != "all":
        rows = [r for r in rows if r["status"] == filter]
    if difficulty != "all":
        rows = [r for r in rows if r["difficulty"] == difficulty]

    pool_size = bank.pool_size(topic)
    availability = mode_availability(pool_size)

    return templates.TemplateResponse(
        request,
        "topic_detail.html",
        {
            **base_context(request),
            "active_nav": "topics",
            "topic": topic,
            "rows": rows,
            "counts": counts,
            "filter": filter,
            "difficulty_counts": difficulty_counts,
            "selected_difficulty": difficulty,
            "pool_size": pool_size,
            "session_size": min(pool_size, SESSION_SIZE),
            "fixed_available": availability["fixed"],
            "randomized_available": availability["randomized"],
            "mixed_available": len(bank) > SESSION_SIZE,
            "topic_timer_minutes": TOPIC_TIMER_SECONDS // 60,
            "mixed_timer_minutes": MIXED_TIMER_SECONDS // 60,
            "timer_choices_minutes": TIMER_CHOICES_MINUTES,
            # Boss mini-exam unlock state - see
            # profile_store.boss_unlocked's docstring for why this reuses
            # the clean-sweep achievement rather than a second flag.
            "boss_unlocked": profile_store.boss_unlocked(topic, user_id=auth.current_user_id(request.session)),
            "boss_session_size": min(pool_size, BOSS_SESSION_SIZE),
            "boss_timer_minutes": BOSS_TIMER_MINUTES,
        },
    )


@router.get("/practice-tests")
def practice_tests(request: Request):
    """Topic-scoped practice sets reframed with real
    correct-rate/attempt-count from the stored profile, per the Figma prototype's
    "Practice Tests" page. Note on scope: there is no per-*session*
    attempt history here (Fixed/Randomized sessions were never recorded as
    discrete attempts, unlike Mixed - see record_exam_attempt()) - "attempts"
    below is the sum of each topic's individual question-level Check
    attempts instead, which needs no new session-history data structure and
    still answers the real question ("have I engaged with this topic, and
    how well am I doing"). Revisit if per-session history turns out to
    matter more than this.
    """
    bank.refresh()
    profile = profile_store.get_profile(auth.current_user_id(request.session))
    questions_status = profile.spec.get("questions", {})

    topic_stats = []
    for topic in bank.topics():
        topic_qids = [q.id for q in bank.questions if q.topic == topic]
        pool_size = bank.pool_size(topic)
        availability = mode_availability(pool_size)
        topic_stats.append({
            "name": topic,
            "pool_size": pool_size,
            "session_size": min(pool_size, SESSION_SIZE),
            "attempts": sum(questions_status.get(qid, {}).get("attempts", 0) for qid in topic_qids),
            "correct_pct": topic_progress_pct(profile.spec, topic_qids),
            "randomized_available": availability["randomized"],
            "mixed_available": len(bank) > SESSION_SIZE,
        })

    attempted = [t for t in topic_stats if t["attempts"] > 0]
    focus_area = min(attempted, key=lambda t: t["correct_pct"]) if attempted else None
    avg_score = round(sum(t["correct_pct"] for t in attempted) / len(attempted)) if attempted else 0

    return templates.TemplateResponse(
        request,
        "practice_tests.html",
        {
            **base_context(request),
            "active_nav": "practice-tests",
            "topic_stats": topic_stats,
            "focus_area": focus_area,
            "total_attempts": sum(t["attempts"] for t in topic_stats),
            "avg_score": avg_score,
            "practice_sets_count": len(topic_stats),
            "topic_timer_minutes": TOPIC_TIMER_SECONDS // 60,
        },
    )


@router.get("/progress")
def progress_page(request: Request):
    """The analytics dashboard, backed
    by real stored profile data - stat cards, a 30-day activity chart, topic
    breakdown, and a skill radar (rendered client-side by app.js from the
    `radar_domains` JSON below).
    """
    bank.refresh()
    profile = profile_store.get_profile(auth.current_user_id(request.session))
    spec = profile.spec
    questions_status = spec.get("questions", {})

    topics_started = sum(
        1 for topic in bank.topics()
        if any(questions_status.get(q.id, {}).get("attempts", 0) > 0 for q in bank.questions if q.topic == topic)
    )

    total_attempts_all = sum(v.get("attempts", 0) for v in questions_status.values())
    correct_count = spec.get("correctCount", 0)
    correct_rate = round(100 * correct_count / total_attempts_all) if total_attempts_all else 0

    daily = spec.get("dailyActivity", {})
    today = datetime.now(timezone.utc).date()
    daily_activity = [
        {"date": (today - timedelta(days=i)).isoformat(), "count": daily.get((today - timedelta(days=i)).isoformat(), 0)}
        for i in range(29, -1, -1)
    ]
    daily_activity_max = max((d["count"] for d in daily_activity), default=0)

    topic_breakdown = sorted(
        (
            {"name": topic, "pct": topic_progress_pct(spec, [q.id for q in bank.questions if q.topic == topic])}
            for topic in bank.topics()
        ),
        key=lambda t: -t["pct"],
    )

    radar_domains = [
        {"name": name, "pct": round(100 * d.get("correct", 0) / d["answered"]) if d.get("answered") else 0}
        for name, d in spec.get("domains", {}).items()
    ]

    return templates.TemplateResponse(
        request,
        "progress.html",
        {
            **base_context(request),
            "active_nav": "progress",
            "questions_answered": correct_count,
            "questions_total": len(bank),
            "correct_rate": correct_rate,
            "streak_days": spec.get("streakDays", 0),
            "topics_started": topics_started,
            "topics_total": len(bank.topics()),
            "daily_activity": daily_activity,
            "daily_activity_max": daily_activity_max,
            "daily_activity_total": sum(d["count"] for d in daily_activity),
            "topic_breakdown": topic_breakdown,
            "radar_domains": radar_domains,
        },
    )


# The 5 official CKAD exam domains and their weights, used by the
# Mock Exam page's readiness view - a static table, not derived from
# anything on disk, since the exam's own weighting is a fixed external fact
# (kubernetes.io's CKAD curriculum), not something this repo's question
# pool structure determines.
CNCF_DOMAIN_WEIGHTS = [
    {"name": "Application Design and Build", "weight": 20},
    {"name": "Application Deployment", "weight": 20},
    {"name": "Application Observability and Maintenance", "weight": 15},
    {"name": "Application Environment, Configuration and Security", "weight": 25},
    {"name": "Services and Networking", "weight": 20},
]

# The real CKAD exam's own pass mark - another fixed external fact (like
# CNCF_DOMAIN_WEIGHTS above), not something this repo computes.
EXAM_PASS_MARK_PCT = 66


@router.get("/mock-exam")
def mock_exam_page(request: Request):
    """The true exam-condition mock exam's setup/landing page - domain
    weights, past attempts (record_exam_attempt() writes these; called by
    routers/sessions_router.py's submit_exam() for exam-mode sessions,
    mirroring end_session() doing so for today's Mixed sessions), and
    per-domain readiness, plus the exam setup
    form itself (topics/difficulty mix/question count/timer). Boss mini-
    exam mode and the daily mixed challenge are deliberately deferred this
    pass - see the "Coming soon" panel in the template rather than a
    half-working game mechanic.
    """
    bank.refresh()
    profile = profile_store.get_profile(auth.current_user_id(request.session))
    spec = profile.spec
    domains = spec.get("domains", {})
    readiness = [
        {
            "name": dw["name"],
            "weight": dw["weight"],
            "pct": round(100 * domains.get(dw["name"], {}).get("correct", 0) / domains[dw["name"]]["answered"])
            if domains.get(dw["name"], {}).get("answered") else 0,
        }
        for dw in CNCF_DOMAIN_WEIGHTS
    ]

    return templates.TemplateResponse(
        request,
        "mock_exam.html",
        {
            **base_context(request),
            "active_nav": "mock-exam",
            "exam_available": len(bank) > 0,
            "exam_topics": bank.topics(),
            "exam_question_count_choices": EXAM_QUESTION_COUNT_CHOICES,
            "exam_default_question_count": EXAM_DEFAULT_QUESTION_COUNT,
            "timer_choices_minutes": TIMER_CHOICES_MINUTES,
            "exam_default_timer_minutes": default_exam_timer_minutes(EXAM_DEFAULT_QUESTION_COUNT),
            "exam_attempts": list(reversed(spec.get("examAttempts", []))),
            "domain_weights": CNCF_DOMAIN_WEIGHTS,
            "readiness": readiness,
            "active_session": session_store.get(auth.current_user_id(request.session)),
        },
    )


@router.get("/sessions/results")
def exam_results_page(request: Request):
    """The exam results view - read once from
    sessions.exam_result_store, written by routers/sessions_router.py's
    submit_exam() the moment an exam finishes grading. Not itself the
    durable record (that's profile_store.record_exam_attempt(), already
    called by submit_exam and already visible on /mock-exam's "Past
    attempts" panel) - this is the one-time "here's exactly what you got
    right and wrong just now" view a real exam never gives you.

    No exam ever submitted (or the process restarted since) means nothing
    to show - redirected back to /mock-exam rather than a bare 404/empty
    page, same "graceful, not an error" posture as every other missing-
    state case in this app.
    """
    user_id = auth.current_user_id(request.session)
    result = exam_result_store.get(user_id)
    if result is None:
        return RedirectResponse(url="/mock-exam")

    domain_rows = [
        {"name": dw["name"], "weight": dw["weight"], "pct": result.domain_breakdown.get(dw["name"], 0)}
        for dw in CNCF_DOMAIN_WEIGHTS
    ]
    pass_pct = round(100 * result.score / result.total) if result.total else 0

    return templates.TemplateResponse(
        request,
        "exam_results.html",
        {
            **base_context(request),
            "active_nav": "mock-exam",
            "score": result.score,
            "total": result.total,
            "pass_pct": pass_pct,
            "passed_exam": pass_pct >= EXAM_PASS_MARK_PCT,
            "pass_mark_pct": EXAM_PASS_MARK_PCT,
            "duration_minutes": result.duration_sec // 60,
            "domain_rows": domain_rows,
            "questions": result.questions,
        },
    )
