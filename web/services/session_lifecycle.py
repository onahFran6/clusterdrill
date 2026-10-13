"""Attempt lifecycle shared by HTTP routes and the server deadline scheduler.

All operations run in worker threads under a per-user lock.
Cleanup completes before a replacement attempt can provision its workspace.
"""
from __future__ import annotations

import logging
import shutil
import time

import profile_store
from fastapi import HTTPException
from grading_client import run_batch_cleanup, run_check, run_freeze_exam_namespaces
from sessions import ActiveSession, ExamResult, exam_result_store
from sessions import store as session_store
from ttyd_manager import manager as ttyd_manager

from questions import LIB_DIR, bank
from services import question_view

logger = logging.getLogger("clusterdrill.session_lifecycle")


def _cleanup_finished_session(
    session: ActiveSession, user_id: str | None,
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
    # Complete cleanup under the attempt lock before another session may
    # provision the same namespace or workspace. Do not queue stale cleanup.
    # batch_cleanup's own bounded poll (lib/grading.sh) is what actually makes
    # that true; a non-ok result here means it gave up before confirming
    # termination - log it for real instead of discarding the result, since
    # the only other place this gets another chance is the next process's
    # startup sweep.
    try:
        result = run_batch_cleanup(session.question_ids, LIB_DIR, user_id)
        if not result.ok:
            logger.error(
                "session cleanup incomplete for user_id=%r question_ids=%r: %s",
                user_id, session.question_ids, result.error,
            )
    except Exception:
        logger.exception("session cleanup failed for user_id=%r", user_id)
    # Mirrors the cluster-side cleanup above but for each question's local
    # working directory (question_workdir) - a plain local rmtree, fast
    # enough to do inline rather than via background_tasks. Same "not
    # coming back" reasoning: any question re-provisions its directory
    # fresh (question_context's mkdir) the next time it's actually viewed
    # again, in this session or a future one.
    for qid in session.question_ids:
        shutil.rmtree(question_view.question_workdir(qid), ignore_errors=True)


def finalize_exam(user_id: str | None = None, attempt_id: str | None = None, reason: str = "manual") -> ExamResult:
    """Grade and finish once; duplicate submits return the stored result."""
    with session_store.lock(user_id):
        session = session_store.get(user_id)
        previous = exam_result_store.get(user_id)
        if previous and ((attempt_id and previous.attempt_id == attempt_id) or (session is None and not attempt_id)):
            return previous
        if session is None or session.mode != "exam":
            raise HTTPException(status_code=400, detail="no active exam session to submit")
        if attempt_id and session.attempt_id != attempt_id:
            raise HTTPException(status_code=409, detail="This exam attempt is no longer active")
        if session.finalization_started_at is None:
            session.finalization_started_at = time.time()
        if session.deadline is not None and session.finalization_started_at >= session.deadline:
            reason = "deadline"
        if session.final_result is None:
            # Two independent write-authority revocations before running a
            # single check.sh (R11), neither of which is the other's
            # fallback - both run every time, best-effort, logged not
            # raised (a failure here must not block finalization itself
            # from completing and recording whatever check.sh actually
            # found):
            #
            # 1. kill_user_tmux_sessions - the one that actually matters in
            # the live, single-trusted-operator app (ADR 0008): the
            # terminal there inherits the application's own full
            # kubeconfig directly (ttyd_manager._spawn_env returns early
            # under single_user_mode(), applying no per-namespace
            # restriction at all), so the only way to stop it from
            # mutating cluster state mid-grading is to kill the shell
            # process itself - a `tmux kill-server` on this user_id's
            # private socket, severing any command (including a
            # background loop) still running in it, not merely closing the
            # browser's view of it.
            #
            # 2. run_freeze_exam_namespaces - revokes the namespace-scoped
            # RoleBinding grant_user_namespace_access creates. A genuine
            # defense-in-depth fix, but currently a no-op in the live app
            # for the same reason (1) exists: single_user_mode() means
            # that RoleBinding was never granted to begin with. Kept
            # correct on its own terms for the retained-but-unreachable
            # per-user-ServiceAccount mechanism (same rationale as every
            # other piece of that machinery - see ADR 0008/0010), not
            # because it does anything today.
            try:
                ttyd_manager.kill_user_tmux_sessions(user_id)
            except Exception:
                logger.exception("exam terminal teardown failed for user_id=%r", user_id)
            try:
                freeze_result = run_freeze_exam_namespaces(session.question_ids, LIB_DIR, user_id)
                if not freeze_result.ok:
                    logger.error(
                        "exam namespace freeze incomplete for user_id=%r question_ids=%r: %s",
                        user_id, session.question_ids, freeze_result.error,
                    )
            except Exception:
                logger.exception("exam namespace freeze failed for user_id=%r", user_id)
            for qid in session.question_ids:
                if qid in session.graded_questions:
                    continue
                question = bank.get(qid)
                result = run_check(question.check_sh, user_id=user_id) if question and question.check_sh.exists() else None
                session.graded_questions[qid] = {
                    "id": qid, "domain": question.domain if question else None,
                    "passed": bool(result and result.ok and result.total > 0 and result.passed == result.total),
                }
            questions = [session.graded_questions[qid] for qid in session.question_ids]
            domains: dict[str, list[int]] = {}
            for question in questions:
                if question["domain"]:
                    counts = domains.setdefault(question["domain"], [0, 0])
                    counts[0] += question["passed"]
                    counts[1] += 1
            finished_at = min(session.finalization_started_at, session.deadline) if session.deadline else session.finalization_started_at
            session.final_result = ExamResult(
                score=sum(q["passed"] for q in questions), total=len(questions),
                duration_sec=max(0, round(finished_at - session.started_at)),
                domain_breakdown={domain: round(100 * passed / count) for domain, (passed, count) in domains.items()},
                questions=questions, attempt_id=session.attempt_id, reason=reason,
            )
        result = session.final_result
        if not session.result_recorded:
            profile_store.record_exam_attempt(
                score=result.score, total=result.total, duration_sec=result.duration_sec,
                domain_breakdown=result.domain_breakdown, user_id=user_id,
            )
            session.result_recorded = True
        exam_result_store.set(result, user_id)
        _cleanup_finished_session(session, user_id)
        session_store.clear(user_id)
        return result


def replace_session(session: ActiveSession, user_id: str | None = None) -> None:
    with session_store.lock(user_id):
        previous = session_store.get(user_id)
        if previous is not None:
            if previous.mode == "exam":
                finalize_exam(user_id, previous.attempt_id)
            else:
                _cleanup_finished_session(previous, user_id)
        session_store.set_active(session, user_id)


def end_attempt(user_id: str | None = None):
    with session_store.lock(user_id):
        session = session_store.get(user_id)
        if session is not None and session.mode == "exam":
            result = finalize_exam(user_id, session.attempt_id)
            return {"ok": True, "score": result.score, "total": result.total}
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
            _cleanup_finished_session(session, user_id)

        session_store.clear(user_id)
        return {"ok": True}


def expire_exam(user_id: str | None, attempt_id: str) -> None:
    """Recheck the captured identity/deadline under lock before acting."""
    with session_store.lock(user_id):
        session = session_store.get(user_id)
        if session is None or session.attempt_id != attempt_id or session.mode != "exam":
            return
        if session.deadline is None or time.time() < session.deadline:
            return
        try:
            finalize_exam(user_id, attempt_id, reason="deadline")
        except Exception:
            # Keep the attempt and grading checkpoints for the next tick.
            logger.exception("exam finalization failed for user_id=%r", user_id)
