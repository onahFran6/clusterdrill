"""Practice-session start/end routes - extracted from app.py's original
monolith (2026-08 restructure) with no behavior change, just a new home.

Distinct from idle.py/routers/idle_router.py's cluster-access lifecycle -
this only ever decides which question ids are "in play" for
navigation/progress purposes, per sessions.py's own module docstring.
"""
from __future__ import annotations

import auth
import profile_store
from fastapi import APIRouter, Depends, Form, HTTPException
from fastapi.responses import RedirectResponse
from services import session_lifecycle
from sessions import (
    MAX_TIMER_MINUTES,
    mode_availability,
    start_boss,
    start_daily,
    start_exam,
    start_fixed,
    start_mixed,
    start_randomized,
)
from starlette.requests import Request

from questions import bank, canonical_topic

router = APIRouter()


@router.post("/sessions/start", dependencies=[Depends(auth.csrf_protect_form)])
def start_session(
    request: Request,
    mode: str = Form(...),
    topic: str = Form(""),
    difficulty: str = Form(""),
    timer_minutes: int | None = Form(None),
    session_size: str = Form(""),
    topics: list[str] = Form([]),
    difficulties: list[str] = Form([]),
    topic_scope: str = Form("all"),
    question_count: int | None = Form(None),
):
    """Starts a new active session and redirects into its first question.

    mode is one of "fixed" | "randomized" | "mixed" | "exam". topic is
    required for fixed/randomized (which topic's pool to draw from) and
    ignored for mixed/exam.
    This is the only place an ActiveSession is created, so gating (mode
    availability) is enforced here even though the landing page also hides
    disabled options in its own UI - never trust client-side disabling
    alone for the actual selection logic.

    Custom timers accept whole minutes from 1 to MAX_TIMER_MINUTES.
    Practice session_size and exam question_count accept positive counts,
    capped to the matching pool by sessions.py. Omitted values use the
    existing defaults; legacy practice "all" remains supported.
    Invalid explicit values are rejected before replacing an active session.

    Every session is timed automatically now (see sessions.py's revision
    note) - there used to be a "timer" form checkbox here; it's
    gone because a lab session always runs its clock the moment it starts,
    the same way a real timed lab does, not something you opt into.
    """
    topic = canonical_topic(topic)
    bank.refresh()
    if mode not in ("fixed", "randomized", "mixed", "exam"):
        raise HTTPException(status_code=400, detail=f"unknown session mode '{mode}'")
    if timer_minutes is not None and not 1 <= timer_minutes <= MAX_TIMER_MINUTES:
        raise HTTPException(status_code=422, detail=f"Timer must be between 1 and {MAX_TIMER_MINUTES} minutes.")
    if mode == "exam" and question_count is not None and question_count < 1:
        raise HTTPException(status_code=422, detail="Enter a positive whole number of questions.")
    if mode != "exam" and session_size not in ("", "all"):
        try:
            if int(session_size) < 1:
                raise ValueError
        except ValueError:
            raise HTTPException(status_code=422, detail="Enter a positive whole number of questions.") from None
    difficulty = difficulty if difficulty in ("easy", "medium", "hard") else None

    if mode == "exam":
        if len(bank) == 0:
            raise HTTPException(status_code=404, detail="no questions discovered in the bank")
        topics = list(dict.fromkeys(canonical_topic(value) for value in topics))
        unknown_topics = set(topics) - set(bank.topics())
        if unknown_topics:
            raise HTTPException(status_code=404, detail=f"unknown topic(s) {sorted(unknown_topics)}")
        session = start_exam(
            bank,
            topics=topics or None,
            difficulties=[d for d in difficulties if d in ("easy", "medium", "hard")] or None,
            question_count=question_count or None,
            timer_minutes=timer_minutes or None,
        )
    elif mode == "mixed":
        topics = list(dict.fromkeys(canonical_topic(value) for value in topics))
        if topic_scope == "selected" and not topics:
            raise HTTPException(status_code=422, detail="Choose at least one topic.")
        unknown_topics = set(topics) - set(bank.topics())
        if unknown_topics:
            raise HTTPException(status_code=404, detail=f"unknown topic(s) {sorted(unknown_topics)}")
        if len(bank) == 0:
            raise HTTPException(status_code=404, detail="no questions discovered in the bank")
        session = start_mixed(
            bank, difficulty=difficulty, timer_minutes=timer_minutes or None, question_count=session_size,
            topics=topics or None,
        )
    else:
        if topic not in bank.topics():
            raise HTTPException(status_code=404, detail=f"unknown topic '{topic}'")
        # The baseline mode gate (unfiltered pool size) still applies -
        # a difficulty filter can only ever narrow a pool further, never
        # unlock a mode the whole topic doesn't support, so this check
        # doesn't need its own difficulty-aware variant. A filter that
        # narrows the pool to fewer than SESSION_SIZE just yields a
        # shorter session (same graceful behavior start_fixed already has
        # for a small topic) rather than a hard error - only a filter that
        # empties the pool entirely fails, via the question_ids check below.
        pool_size = bank.pool_size(topic)
        availability = mode_availability(pool_size)
        if not availability[mode]:
            raise HTTPException(
                status_code=400,
                detail=f"mode '{mode}' is not available for topic '{topic}' "
                f"(pool size {pool_size})",
            )
        session = (
            start_fixed(
                bank, topic, difficulty=difficulty, timer_minutes=timer_minutes or None,
                question_count=session_size,
            )
            if mode == "fixed"
            else start_randomized(
                bank, topic, difficulty=difficulty, timer_minutes=timer_minutes or None,
                question_count=session_size,
            )
        )

    if not session.question_ids:
        raise HTTPException(status_code=404, detail="selected topic/pool has no questions")

    user_id = auth.current_user_id(request.session)
    session_lifecycle.replace_session(session, user_id)
    return RedirectResponse(url=f"/questions/{session.question_ids[0]}", status_code=303)


@router.post("/sessions/start-boss", dependencies=[Depends(auth.csrf_protect_form)])
def start_boss_session(request: Request, topic: str = Form(...)):
    """Starts a topic's boss mini-exam - a separate route from
    /sessions/start rather than a fourth `mode` value there, since a boss
    fight has none of the regular session-setup panel's choices (no
    difficulty filter, no timer_minutes override - always the full pool,
    always BOSS_TIMER_SECONDS, see start_boss's docstring) and has its own
    gate (profile_store.boss_unlocked) that the other three modes don't.
    """
    topic = canonical_topic(topic)
    bank.refresh()
    if topic not in bank.topics():
        raise HTTPException(status_code=404, detail=f"unknown topic '{topic}'")

    user_id = auth.current_user_id(request.session)
    if not profile_store.boss_unlocked(topic, user_id=user_id):
        raise HTTPException(
            status_code=403,
            detail=f"boss fight for '{topic}' is locked - clear a full session for this topic first",
        )

    session = start_boss(bank, topic)
    if not session.question_ids:
        raise HTTPException(status_code=404, detail="selected topic has no questions")

    session_lifecycle.replace_session(session, user_id)
    return RedirectResponse(url=f"/questions/{session.question_ids[0]}", status_code=303)


@router.post("/sessions/start-daily", dependencies=[Depends(auth.csrf_protect_form)])
def start_daily_session(request: Request):
    """Starts the daily/session mixed challenge - deliberately no
    form fields at all (no topic, no difficulty, no timer override; see
    start_daily's docstring for why) and no unlock gate, unlike
    /sessions/start-boss - it's always available, "its own small reward
    track separate from the topic labs" per the ticket, not something you
    earn access to.
    """
    bank.refresh()
    if len(bank) == 0:
        raise HTTPException(status_code=404, detail="no questions discovered in the bank")

    session = start_daily(bank)
    if not session.question_ids:
        raise HTTPException(status_code=404, detail="no questions available")

    user_id = auth.current_user_id(request.session)
    session_lifecycle.replace_session(session, user_id)
    return RedirectResponse(url=f"/questions/{session.question_ids[0]}", status_code=303)


@router.post("/sessions/submit", dependencies=[Depends(auth.csrf_protect_header)])
def submit_exam(request: Request, attempt_id: str | None = None):
    result = session_lifecycle.finalize_exam(auth.current_user_id(request.session), attempt_id)
    return {"ok": True, "score": result.score, "total": result.total}


@router.post("/sessions/end", dependencies=[Depends(auth.csrf_protect_header)])
def end_session(request: Request):
    return session_lifecycle.end_attempt(auth.current_user_id(request.session))
