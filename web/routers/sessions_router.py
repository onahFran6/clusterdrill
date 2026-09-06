"""Practice-session start/end routes - extracted from app.py's original
monolith (2026-08 restructure) with no behavior change, just a new home.

Distinct from idle.py/routers/idle_router.py's cluster-access lifecycle -
this only ever decides which question ids are "in play" for
navigation/progress purposes, per sessions.py's own module docstring.
"""
from __future__ import annotations

import shutil
import time

import auth
import profile_store
from fastapi import APIRouter, BackgroundTasks, Depends, Form, HTTPException
from fastapi.responses import RedirectResponse
from grading_client import run_batch_cleanup, run_check
from services import question_view
from sessions import (
    ActiveSession,
    ExamResult,
    exam_result_store,
    mode_availability,
    start_boss,
    start_daily,
    start_exam,
    start_fixed,
    start_mixed,
    start_randomized,
)
from sessions import (
    store as session_store,
)
from starlette.requests import Request

from questions import LIB_DIR, bank

router = APIRouter()


@router.post("/sessions/start", dependencies=[Depends(auth.csrf_protect_form)])
def start_session(
    request: Request,
    mode: str = Form(...),
    topic: str = Form(""),
    difficulty: str = Form(""),
    timer_minutes: int = Form(0),
    topics: list[str] = Form([]),
    difficulties: list[str] = Form([]),
    question_count: int = Form(0),
):
    """Starts a new active session and redirects into its first question.

    mode is one of "fixed" | "randomized" | "mixed" | "exam". topic is
    required for fixed/randomized (which topic's pool to draw from) and
    ignored for mixed/exam.
    This is the only place an ActiveSession is created, so gating (mode
    availability) is enforced here even though the landing page also hides
    disabled options in its own UI - never trust client-side disabling
    alone for the actual selection logic.

    difficulty ("" | "easy" | "medium" | "hard") and timer_minutes (0 means
    "use the mode's default") are fixed/randomized/mixed's session-setup
    panel choices - both optional, both validated again inside sessions.py
    (an unknown difficulty string quietly yields an empty pool rather than
    a 500; an out-of-preset timer_minutes falls back to the default) so a
    forged form post can't do anything worse than "no questions matched" or
    "ran with the default clock."

    topics/difficulties/question_count are exam mode's own setup-form
    fields - a multi-select of topics and a
    multi-select difficulty mix (plural, distinct from fixed/randomized/
    mixed's single-select difficulty above - the exam setup form's
    checkboxes post repeated same-named fields, not one value) plus a
    question-count preset. Same "validated again in sessions.py, an
    unknown/out-of-preset value just falls back to a default" rule as
    every other field here - ignored entirely for every mode but exam.

    Every session is timed automatically now (see sessions.py's revision
    note) - there used to be a "timer" form checkbox here; it's
    gone because a lab session always runs its clock the moment it starts,
    the same way a real timed lab does, not something you opt into.
    """
    bank.refresh()
    if mode not in ("fixed", "randomized", "mixed", "exam"):
        raise HTTPException(status_code=400, detail=f"unknown session mode '{mode}'")
    difficulty = difficulty if difficulty in ("easy", "medium", "hard") else None

    if mode == "exam":
        if len(bank) == 0:
            raise HTTPException(status_code=404, detail="no questions discovered in the bank")
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
        if len(bank) == 0:
            raise HTTPException(status_code=404, detail="no questions discovered in the bank")
        session = start_mixed(bank, difficulty=difficulty, timer_minutes=timer_minutes or None)
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
            start_fixed(bank, topic, difficulty=difficulty, timer_minutes=timer_minutes or None)
            if mode == "fixed"
            else start_randomized(bank, topic, difficulty=difficulty, timer_minutes=timer_minutes or None)
        )

    if not session.question_ids:
        raise HTTPException(status_code=404, detail="selected topic/pool has no questions")

    session_store.set_active(session, auth.current_user_id(request.session))
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

    session_store.set_active(session, user_id)
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

    session_store.set_active(session, auth.current_user_id(request.session))
    return RedirectResponse(url=f"/questions/{session.question_ids[0]}", status_code=303)


def _cleanup_finished_session(
    session: ActiveSession, user_id: str | None, background_tasks: BackgroundTasks,
) -> None:
    """Shared tail of end_session/submit_exam below: a finished session's
    questions aren't coming back, so their auto-provision cache entry,
    cluster namespaces, and local working directories shouldn't either.
    Grading itself is unaffected either way - this only ever runs *after*
    grading (Check calls above, or submit_exam's batch of them) has
    already produced whatever result it produced.
    """
    if not session.question_ids:
        return
    question_view._auto_provisioned_qids.difference_update(
        (qid, user_id) for qid in session.question_ids
    )
    background_tasks.add_task(run_batch_cleanup, session.question_ids, LIB_DIR, user_id)
    # Mirrors the cluster-side cleanup above but for each question's local
    # working directory (question_workdir) - a plain local rmtree, fast
    # enough to do inline rather than via background_tasks. Same "not
    # coming back" reasoning: any question re-provisions its directory
    # fresh (question_context's mkdir) the next time it's actually viewed
    # again, in this session or a future one.
    for qid in session.question_ids:
        shutil.rmtree(question_view.question_workdir(qid), ignore_errors=True)


@router.post("/sessions/submit", dependencies=[Depends(auth.csrf_protect_header)])
def submit_exam(request: Request, background_tasks: BackgroundTasks):
    """The submit-and-score step that follows
    the deferred-grading behavior: runs check.sh once per question in the
    active exam session, server-side, all at once - nothing shown to the
    candidate mid-run, matching how no live feedback was shown during the
    exam either. Exam mode only; any other active session (or none at
    all) is a 400 - there's nothing to "submit" for a live-feedback mode,
    where every Check already produced its own final answer as it
    happened.

    Deliberately does NOT call profile_store.record_check() per question
    (unlike the interactive /questions/{qid}/check route) - the ticket's
    own scope is "aggregate into a score, call record_exam_attempt()",
    not "also feed each question's per-question stats/achievements". An
    exam attempt's per-question detail lives only in the ephemeral
    ExamResult below (read once by GET /sessions/results), not folded into
    the profile's durable per-question history.
    """
    user_id = auth.current_user_id(request.session)
    session = session_store.get(user_id)
    if session is None or session.mode != "exam":
        raise HTTPException(status_code=400, detail="no active exam session to submit")

    bank.refresh()
    per_question: list[dict] = []
    passed_count = 0
    domain_totals: dict[str, list[int]] = {}
    for qid in session.question_ids:
        question = bank.get(qid)
        result = run_check(question.check_sh, user_id=user_id) if question and question.check_sh.exists() else None
        fully_passed = bool(result and result.ok and result.total > 0 and result.passed == result.total)
        if fully_passed:
            passed_count += 1
        domain = question.domain if question else None
        if domain:
            counts = domain_totals.setdefault(domain, [0, 0])
            counts[1] += 1
            if fully_passed:
                counts[0] += 1
        per_question.append({"id": qid, "domain": domain, "passed": fully_passed})

    total = len(session.question_ids)
    domain_breakdown = {
        domain: round(100 * passed / count) if count else 0
        for domain, (passed, count) in domain_totals.items()
    }
    duration_sec = round(time.time() - session.started_at)

    profile_store.record_exam_attempt(
        score=passed_count, total=total, duration_sec=duration_sec,
        domain_breakdown=domain_breakdown, user_id=user_id,
    )
    exam_result_store.set(
        ExamResult(
            score=passed_count, total=total, duration_sec=duration_sec,
            domain_breakdown=domain_breakdown, questions=per_question,
        ),
        user_id,
    )

    _cleanup_finished_session(session, user_id, background_tasks)
    session_store.clear(user_id)
    return {"ok": True, "score": passed_count, "total": total}


@router.post("/sessions/end", dependencies=[Depends(auth.csrf_protect_header)])
def end_session(request: Request, background_tasks: BackgroundTasks):
    """Ends the active session early - the explicit "End session" action in
    the status-bar footer, and also what the timer's client-side expiry
    calls automatically (app.js). Clears which question ids are "in play"
    for navigation/progress purposes, and also schedules a best-effort
    cluster cleanup (batch_cleanup, see lib/grading.sh) for every question
    that was in this batch - a finished session's questions aren't coming
    back, so their namespaces shouldn't either. Grading itself is still
    entirely unaffected by any of this - cleanup runs as a background task
    *after* this response is sent, so "End session" stays fast regardless
    of cluster responsiveness, and Check/Reset for a question you revisit
    later still just work (setup.sh auto-re-provisions on next view - see
    services/question_view.py's question_context() auto-provision block).
    A no-op (not an error) if nothing is active - both a manual double
    click and an already-expired timer calling this again should be safe.

    A Mixed session ending (early or via timeout) is recorded as a
    Mock Exam attempt - score, duration, and a per-domain breakdown of this
    specific run, used by the Mock Exam page's "Past attempts"/readiness
    view. Fixed/Randomized sessions aren't exam simulations, so they don't
    record an attempt here (they already feed Practice Tests' best-score
    view through record_check's per-question data).
    """
    user_id = auth.current_user_id(request.session)
    session = session_store.get(user_id)
    if session is not None and session.mode == "mixed":
        bank.refresh()
        domain_totals: dict[str, list[int]] = {}
        for qid in session.question_ids:
            question = bank.get(qid)
            domain = question.domain if question else None
            if not domain:
                continue
            counts = domain_totals.setdefault(domain, [0, 0])
            counts[1] += 1
            if qid in session.passed_qids:
                counts[0] += 1
        domain_breakdown = {
            domain: round(100 * passed / total) if total else 0
            for domain, (passed, total) in domain_totals.items()
        }
        profile_store.record_exam_attempt(
            score=len(session.passed_qids),
            total=len(session.question_ids),
            duration_sec=round(time.time() - session.started_at),
            domain_breakdown=domain_breakdown,
            user_id=user_id,
        )

    if session is not None:
        _cleanup_finished_session(session, user_id, background_tasks)

    session_store.clear(user_id)
    return {"ok": True}
