"""Question view/check/reset routes - extracted from app.py's original
monolith (2026-08 restructure) with no behavior change, just a new home.

Grading integrity invariant: the only source of
PASS/FAIL/score data is check.sh's live stdout, parsed by grading_client.py.
There is no endpoint anywhere in this file that accepts a client-supplied
"mark as done" flag.
"""
from __future__ import annotations

import time
from datetime import datetime, timezone
from typing import Optional

import auth
import profile_store
from fastapi import APIRouter, Body, Depends, HTTPException
from grading_client import run_check, run_reset
from services.question_view import base_context, get_question_or_404, question_context
from sessions import BOSS_DAMAGE_SLOW_PASS, BOSS_DAMAGE_WRONG_CHECK, BOSS_MAX_HP
from sessions import store as session_store
from starlette.requests import Request
from templating import templates

from questions import LIB_DIR

router = APIRouter()


@router.get("/questions/{qid}")
def view_question(request: Request, qid: str, tab: str = "task"):
    if tab not in ("task", "hint", "solution", "diagram"):
        tab = "task"
    user_id = auth.current_user_id(request.session)
    ctx = {**base_context(request), **question_context(qid, tab=tab, user_id=user_id)}
    return templates.TemplateResponse(request, "question.html", ctx)


@router.post("/questions/{qid}/check", dependencies=[Depends(auth.csrf_protect_header)])
def check_question(
    request: Request,
    qid: str,
    elapsed_ms: Optional[int] = Body(None),
    used_hint: bool = Body(False),
):
    """Runs check.sh for real and returns parsed PASS/FAIL/score JSON.

    This is the only endpoint the "Check" button's JS calls, and it always
    re-runs the live script - no caching of a prior result as truth.

    elapsed_ms/used_hint are client-tracked (app.js resets
    both on question load/Reset) and only ever used *after* grading has
    already produced its real pass/fail result below - they inform
    progress-tracking (personal-best time, the no-hints achievement), never
    the grading result itself. See profile_store.py's module docstring for
    the same invariant restated at the persistence layer.
    """
    question = get_question_or_404(qid)
    if not question.check_sh.exists():
        raise HTTPException(status_code=500, detail="check.sh missing for this question")

    user_id = auth.current_user_id(request.session)
    result = run_check(question.check_sh, user_id=user_id)
    fully_passed = result.ok and result.total > 0 and result.passed == result.total

    record = profile_store.record_check(
        qid, question.topic, question.domain, passed=fully_passed,
        elapsed_ms=elapsed_ms, used_hint=used_hint, user_id=user_id,
        difficulty=question.difficulty, resource_kind_count=len(question.resource_kinds) or 1,
    )

    session = session_store.get(user_id)
    in_session = session is not None and session.index_of(qid) is not None
    boss_won = False
    if in_session:
        is_boss = session.mode == "boss"
        if fully_passed:
            session.passed_qids.add(qid)
            if qid not in session.failed_qids:
                session.combo += 1
        else:
            session.failed_qids.add(qid)
            session.combo = 0

        if is_boss:
            # A wrong Check always costs HP; a passing-but-slow one
            # (no speed tier earned, see profile_store._speed_tier_for)
            # costs less but still counts as a hit - see BOSS_DAMAGE_* in
            # sessions.py for the reasoning behind both numbers.
            if not fully_passed:
                session.hp = max(0, session.hp - BOSS_DAMAGE_WRONG_CHECK)
            elif record.speed_tier is None:
                session.hp = max(0, session.hp - BOSS_DAMAGE_SLOW_PASS)

            if (
                session.hp > 0
                and (session.deadline is None or time.time() < session.deadline)
                and set(session.question_ids).issubset(session.passed_qids)
            ):
                boss_won = True
                profile_store.apply_boss_defeat(session.topic, user_id=user_id)
        elif session.mode == "daily":
            # No HP/deadline gate like boss above - the daily
            # challenge is "its own small reward track", not a fight with
            # stakes, so simply clearing every drawn question (retries
            # allowed, like boss - no clean-sweep-style zero-fails
            # requirement either) earns today's reward. Keyed on the
            # calendar date, not the session's specific question ids, so
            # re-rolling and clearing a second draw the same day is still
            # just the same day's one reward (see apply_daily_challenge_
            # clear's docstring).
            if set(session.question_ids).issubset(session.passed_qids):
                today = datetime.now(timezone.utc).date().isoformat()
                profile_store.apply_daily_challenge_clear(today, user_id=user_id)
        elif (
            session.topic is not None
            and not session.failed_qids
            and set(session.question_ids).issubset(session.passed_qids)
        ):
            profile_store.apply_clean_sweep(session.topic, user_id=user_id)

    return {
        "ok": result.ok,
        "error": result.error,
        "passed": result.passed,
        "total": result.total,
        "criteria": [{"description": c.description, "passed": c.passed} for c in result.criteria],
        "profile_xp": record.profile.spec.get("xp"),
        "profile_best_time_ms": record.profile.spec.get("questions", {}).get(qid, {}).get("bestTimeMs"),
        "speed_tier": record.speed_tier,
        "profile_best_speed_tier": record.profile.spec.get("questions", {}).get(qid, {}).get("bestSpeedTier"),
        "new_achievements": record.new_achievements,
        "combo": session.combo if in_session else 0,
        "boss_hp": session.hp if in_session and session.mode == "boss" else None,
        "boss_max_hp": BOSS_MAX_HP if in_session and session.mode == "boss" else None,
        "boss_won": boss_won,
    }


@router.post("/questions/{qid}/reset", dependencies=[Depends(auth.csrf_protect_header)])
def reset_question(request: Request, qid: str):
    """full_reset(qid) then setup.sh - always the full teardown+rebuild,
    never a soft reset."""
    question = get_question_or_404(qid)
    if not question.setup_sh.exists():
        raise HTTPException(status_code=500, detail="setup.sh missing for this question")

    user_id = auth.current_user_id(request.session)
    result = run_reset(question.id, question.setup_sh, LIB_DIR, user_id=user_id)
    if not result.ok:
        raise HTTPException(status_code=500, detail=result.error or "reset failed")
    return {"ok": True, "output": result.output}
