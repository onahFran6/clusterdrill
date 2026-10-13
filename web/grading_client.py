"""Runs a question's check.sh (and, for Reset, full_reset + setup.sh) as a
live subprocess and parses lib/grading.sh's stdout contract.

Contract (see practice-bank/lib/grading.sh):
    CRITERION: <description> = PASS
    CRITERION: <description> = FAIL
    ...
    SCORE: <passed>/<total>          # last line

This module never invents its own notion of "done" - it only ever reports
what check.sh printed from the live cluster this run. There is no code path anywhere here that lets a client mark a criterion
passed without running check.sh.

Every function here takes an optional
`user_id`, retained for the underlying CLUSTERDRILL_NAMESPACE_SUFFIX
mechanism's own correctness (every question's `QUESTION_ID="qNNN-..."`
literal was mechanically changed to
`QUESTION_ID="qNNN-...${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"`), but with
single_user_mode() permanently True (R08/Proposal A) there is structurally
only ever one operator, so namespaced_id/_subprocess_env never actually
suffix anything in the live app regardless of what `user_id` is passed -
every question always operates against the bare `qNNN-...` namespace,
unmodified environment passed to the subprocess.
"""
from __future__ import annotations

import contextlib
import os
import re
import signal
import subprocess
from dataclasses import dataclass
from typing import Optional

import users

CRITERION_RE = re.compile(r"^CRITERION:\s*(?P<description>.*?)\s*=\s*(?P<result>PASS|FAIL)\s*$")
SCORE_RE = re.compile(r"^SCORE:\s*(?P<passed>\d+)\s*/\s*(?P<total>\d+)\s*$")

CHECK_TIMEOUT_SECONDS = 60
RESET_TIMEOUT_SECONDS = 120
SETUP_TIMEOUT_SECONDS = 60
BATCH_CLEANUP_TIMEOUT_SECONDS = 45  # grading.sh's own batch_cleanup polls for up to 30s
FREEZE_EXAM_TIMEOUT_SECONDS = 30  # no polling loop - just RoleBinding deletes, one per namespace


def _run_subprocess(argv, *, timeout: float, cwd=None, env=None) -> subprocess.CompletedProcess:
    """Same contract as subprocess.run(capture_output=True, text=True,
    timeout=timeout, cwd=cwd, env=env), except a timeout kills the whole
    process group, not just the immediate `bash` child (I05): a plain
    subprocess.run(timeout=...) only ever signals the direct child, so a
    check.sh/setup.sh that spawned kubectl/helm children of its own left
    them to finish - or hang - unsupervised on every prior timeout here.
    start_new_session=True makes this child its own process group leader so
    one SIGKILL to the group reaches the whole tree.
    """
    proc = subprocess.Popen(
        argv, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
        cwd=cwd, env=env, start_new_session=True,
    )
    try:
        stdout, stderr = proc.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        with contextlib.suppress(ProcessLookupError, PermissionError):
            os.killpg(os.getpgid(proc.pid), signal.SIGKILL)
        stdout, stderr = proc.communicate()
        raise subprocess.TimeoutExpired(argv, timeout, output=stdout, stderr=stderr) from None
    return subprocess.CompletedProcess(argv, proc.returncode, stdout, stderr)


@dataclass
class Criterion:
    description: str
    passed: bool


@dataclass
class CheckResult:
    criteria: list[Criterion]
    passed: int
    total: int
    raw_stdout: str
    raw_stderr: str
    ok: bool  # process ran and we found a SCORE line
    error: str | None = None


def namespaced_id(question_id: str, user_id: Optional[str]) -> str:
    """The namespace/cluster-label value a given question actually operates
    against - bare question_id, unsuffixed. The per-user suffix only existed
    to prevent cross-user namespace collisions; with single_user_mode()
    permanently True (R08/Proposal A) there is structurally only ever one
    operator, so suffixing is a no-op regardless of user_id. Used for
    full_reset/batch_cleanup's own namespace-name argument; setup.sh/check.sh
    compute the identical value themselves via CLUSTERDRILL_NAMESPACE_SUFFIX
    (_subprocess_env below), so both sides always agree on one namespace
    name."""
    if users.single_user_mode():
        return question_id
    return f"{question_id}-{user_id}" if user_id else question_id


def _subprocess_env(user_id: Optional[str]) -> Optional[dict]:
    """None (subprocess.run's own default: inherit the parent env unchanged)
    whenever single_user_mode() - there is only ever one operator, so no
    suffix is ever injected (R08/Proposal A). Falls back to the old
    per-user-suffix behavior if single_user_mode() is ever False again
    (kept correct on its own terms, not reachable by the live app). CLUSTERDRILL_USER_ID is the bare
    user_id, separate from CLUSTERDRILL_NAMESPACE_SUFFIX's leading "-" - setup.sh's
    grant_user_namespace_access call needs the bare id to name the
    ServiceAccount it binds a RoleBinding to, not a namespace suffix."""
    if users.single_user_mode() or not user_id:
        return None
    return {**os.environ, "CLUSTERDRILL_NAMESPACE_SUFFIX": f"-{user_id}", "CLUSTERDRILL_USER_ID": user_id}


def parse_check_output(stdout: str) -> tuple[list[Criterion], int, int, str | None]:
    """Parses lib/grading.sh's CRITERION/SCORE contract and cross-checks the
    SCORE line against what was actually parsed, rather than trusting it at
    face value (R12): a checker that prints a stale/duplicated/impossible
    SCORE line, or one whose numbers disagree with its own CRITERION lines,
    is a broken checker, not a legitimate result. Exit-code validity is
    checked separately by run_check, since this function only ever sees
    stdout.
    """
    criteria: list[Criterion] = []
    passed_count = 0
    total_count = 0
    found_score = False
    duplicate_score = False

    for line in stdout.splitlines():
        line = line.strip()
        m = CRITERION_RE.match(line)
        if m:
            criteria.append(
                Criterion(
                    description=m.group("description"),
                    passed=m.group("result") == "PASS",
                )
            )
            continue
        m = SCORE_RE.match(line)
        if m:
            if found_score:
                duplicate_score = True
            passed_count = int(m.group("passed"))
            total_count = int(m.group("total"))
            found_score = True

    if not found_score:
        return criteria, 0, 0, "no SCORE line found in check.sh output"
    if duplicate_score:
        return criteria, passed_count, total_count, "duplicate SCORE line in check.sh output"
    if passed_count > total_count:
        return criteria, passed_count, total_count, f"impossible SCORE {passed_count}/{total_count}: passed exceeds total"
    actual_passed = sum(1 for c in criteria if c.passed)
    if total_count != len(criteria) or passed_count != actual_passed:
        return (
            criteria, passed_count, total_count,
            f"SCORE {passed_count}/{total_count} does not match "
            f"{actual_passed}/{len(criteria)} parsed CRITERION line(s)",
        )
    return criteria, passed_count, total_count, None


def run_check(check_sh_path, user_id: Optional[str] = None) -> CheckResult:
    """Runs `bash <check_sh_path>` and parses its stdout per the contract.

    Always shells out for real - this is the only source of truth the
    checklist is allowed to reflect.
    """
    try:
        proc = _run_subprocess(
            ["bash", str(check_sh_path)],
            timeout=CHECK_TIMEOUT_SECONDS,
            cwd=str(check_sh_path.parent),
            env=_subprocess_env(user_id),
        )
    except subprocess.TimeoutExpired as exc:
        return CheckResult(
            criteria=[],
            passed=0,
            total=0,
            raw_stdout=exc.stdout or "",
            raw_stderr=exc.stderr or "",
            ok=False,
            error=f"check.sh timed out after {CHECK_TIMEOUT_SECONDS}s",
        )
    except OSError as exc:
        return CheckResult(
            criteria=[], passed=0, total=0, raw_stdout="", raw_stderr="", ok=False,
            error=f"failed to run check.sh: {exc}",
        )

    criteria, passed_count, total_count, error = parse_check_output(proc.stdout)
    # A SCORE line alone was never proof the script actually ran to
    # completion (R12): check.sh can print a convincing SCORE line and then
    # exit nonzero (a trap, a later command failing after print_score, etc).
    # Exit code is still the final word, in addition to - not instead of -
    # the content validation parse_check_output already did.
    if error is None and proc.returncode != 0:
        error = f"check.sh exited {proc.returncode} despite printing a SCORE line"
    return CheckResult(
        criteria=criteria,
        passed=passed_count,
        total=total_count,
        raw_stdout=proc.stdout,
        raw_stderr=proc.stderr,
        ok=error is None,
        error=error,
    )


@dataclass
class ResetResult:
    ok: bool
    output: str
    error: str | None = None


def run_setup(setup_sh_path, user_id: Optional[str] = None) -> ResetResult:
    """Runs setup.sh on its own, no full_reset first.

    Used to auto-provision a question's namespace/seed resources the first
    time it's viewed (real exam questions arrive with their environment
    already in place - a candidate shouldn't have to know to click Reset
    just to get there). setup.sh is idempotent (see its own docstring
    convention: `kubectl create ... --dry-run=client -o yaml | kubectl apply
    -f -`), so running it against an already-provisioned namespace is a
    no-op, not a wipe - unlike run_reset, which always tears down first.
    """
    try:
        proc = _run_subprocess(
            ["bash", str(setup_sh_path)],
            timeout=SETUP_TIMEOUT_SECONDS,
            cwd=str(setup_sh_path.parent),
            env=_subprocess_env(user_id),
        )
    except subprocess.TimeoutExpired as exc:
        return ResetResult(ok=False, output=(exc.stdout or "") + (exc.stderr or ""),
                            error=f"setup timed out after {SETUP_TIMEOUT_SECONDS}s")
    except OSError as exc:
        return ResetResult(ok=False, output="", error=f"failed to run setup: {exc}")

    combined = proc.stdout + proc.stderr
    if proc.returncode != 0:
        return ResetResult(ok=False, output=combined, error=f"setup exited {proc.returncode}")
    return ResetResult(ok=True, output=combined)


def run_batch_cleanup(question_ids: list[str], lib_dir, user_id: Optional[str] = None) -> ResetResult:
    """Bulk-deletes namespaces/cluster-scoped resources for a whole batch of
    questions (see lib/grading.sh's batch_cleanup) - called when a session
    ends, so a finished 15-question run doesn't leave 15 namespaces sitting
    on the cluster forever. Non-blocking on the cluster side (--wait=false
    in batch_cleanup), so this itself returns quickly.
    """
    if not question_ids:
        return ResetResult(ok=True, output="")
    namespaces = [namespaced_id(qid, user_id) for qid in question_ids]
    # Same positional-args discipline as run_reset - question ids come from
    # a session built out of user-facing selections, never string-formatted
    # into the script.
    script = 'set -uo pipefail; source "$1"; shift; batch_cleanup "$@"'
    try:
        proc = _run_subprocess(
            ["bash", "-c", script, "bash", str(lib_dir / "grading.sh"), *namespaces],
            timeout=BATCH_CLEANUP_TIMEOUT_SECONDS,
        )
    except subprocess.TimeoutExpired as exc:
        return ResetResult(ok=False, output=(exc.stdout or "") + (exc.stderr or ""),
                            error=f"batch cleanup timed out after {BATCH_CLEANUP_TIMEOUT_SECONDS}s")
    except OSError as exc:
        return ResetResult(ok=False, output="", error=f"failed to run batch cleanup: {exc}")

    combined = proc.stdout + proc.stderr
    if proc.returncode != 0:
        return ResetResult(ok=False, output=combined, error=f"batch cleanup exited {proc.returncode}")
    return ResetResult(ok=True, output=combined)


def run_freeze_exam_namespaces(question_ids: list[str], lib_dir, user_id: Optional[str] = None) -> ResetResult:
    """Revokes the candidate's own RBAC grant in every namespace belonging
    to these questions (see lib/grading.sh's freeze_exam_namespaces) -
    called at the start of exam finalization (R11), before any check.sh
    runs. Defense-in-depth for grant_user_namespace_access's own retained-
    but-unreachable per-user mechanism (ADR 0008) - currently a no-op in
    the live, single-trusted-operator app, where that RoleBinding is never
    granted in the first place. session_lifecycle.py also calls
    ttyd_manager.kill_user_tmux_sessions alongside this, which is what
    actually severs the live terminal's access (ADR 0010). Namespaces/
    objects themselves are untouched either way; _cleanup_finished_session's
    own run_batch_cleanup call tears them down shortly after regardless.
    """
    if not question_ids:
        return ResetResult(ok=True, output="")
    namespaces = [namespaced_id(qid, user_id) for qid in question_ids]
    script = 'set -uo pipefail; source "$1"; shift; freeze_exam_namespaces "$@"'
    try:
        proc = _run_subprocess(
            ["bash", "-c", script, "bash", str(lib_dir / "grading.sh"), *namespaces],
            timeout=FREEZE_EXAM_TIMEOUT_SECONDS,
        )
    except subprocess.TimeoutExpired as exc:
        return ResetResult(ok=False, output=(exc.stdout or "") + (exc.stderr or ""),
                            error=f"freeze exam namespaces timed out after {FREEZE_EXAM_TIMEOUT_SECONDS}s")
    except OSError as exc:
        return ResetResult(ok=False, output="", error=f"failed to run freeze exam namespaces: {exc}")

    combined = proc.stdout + proc.stderr
    if proc.returncode != 0:
        return ResetResult(ok=False, output=combined, error=f"freeze exam namespaces exited {proc.returncode}")
    return ResetResult(ok=True, output=combined)


def run_reset(question_id: str, setup_sh_path, lib_dir, user_id: Optional[str] = None) -> ResetResult:
    """full_reset <qid> then setup.sh - a clean rebuild from nothing.

    Always the full teardown-and-rebuild - there is no partial/soft reset
    path. `full_reset` is sourced straight from lib/grading.sh so this
    module doesn't duplicate its cleanup logic. Both full_reset's namespace
    argument (namespaced_id) and setup.sh's own internal QUESTION_ID
    (CLUSTERDRILL_NAMESPACE_SUFFIX, via _subprocess_env) get the same per-user
    suffix, so they always agree on which namespace they're tearing down
    and rebuilding.
    """
    namespace = namespaced_id(question_id, user_id)
    # Positional args ($1/$2/$3), not string interpolation - question_id in
    # particular will eventually come from a network-facing UI, so
    # this must never build the shell command by formatting values into it.
    script = 'set -uo pipefail; source "$1" && full_reset "$2" && bash "$3"'
    try:
        proc = _run_subprocess(
            ["bash", "-c", script, "bash", str(lib_dir / "grading.sh"), namespace, str(setup_sh_path)],
            timeout=RESET_TIMEOUT_SECONDS,
            cwd=str(setup_sh_path.parent),
            env=_subprocess_env(user_id),
        )
    except subprocess.TimeoutExpired as exc:
        return ResetResult(ok=False, output=(exc.stdout or "") + (exc.stderr or ""),
                            error=f"reset timed out after {RESET_TIMEOUT_SECONDS}s")
    except OSError as exc:
        return ResetResult(ok=False, output="", error=f"failed to run reset: {exc}")

    combined = proc.stdout + proc.stderr
    if proc.returncode != 0:
        return ResetResult(ok=False, output=combined, error=f"reset exited {proc.returncode}")
    return ResetResult(ok=True, output=combined)
