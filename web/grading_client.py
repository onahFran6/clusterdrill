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
`user_id`. When set, it's passed to the underlying setup.sh/check.sh as the
CLUSTERDRILL_NAMESPACE_SUFFIX env var - every question's `QUESTION_ID="qNNN-..."`
literal was mechanically changed to
`QUESTION_ID="qNNN-...${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"`, so a suffixed env var
makes that question operate against namespace `qNNN-...-<user_id>` instead
of the bare `qNNN-...`, with zero change to any individual question script's
actual logic. `user_id=None` (the default - local dev/SSH-tunnel, no
accounts) reproduces the exact prior behavior: no suffix, unmodified
environment passed to the subprocess.
"""
from __future__ import annotations

import os
import re
import subprocess
from dataclasses import dataclass
from typing import Optional

CRITERION_RE = re.compile(r"^CRITERION:\s*(?P<description>.*?)\s*=\s*(?P<result>PASS|FAIL)\s*$")
SCORE_RE = re.compile(r"^SCORE:\s*(?P<passed>\d+)\s*/\s*(?P<total>\d+)\s*$")

CHECK_TIMEOUT_SECONDS = 60
RESET_TIMEOUT_SECONDS = 120
SETUP_TIMEOUT_SECONDS = 60
BATCH_CLEANUP_TIMEOUT_SECONDS = 30


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
    against - bare question_id with no accounts (user_id=None), or suffixed
    with the owning user's id once accounts are in play. Used for full_reset
    /batch_cleanup's own namespace-name argument; setup.sh/check.sh compute
    the identical value themselves via CLUSTERDRILL_NAMESPACE_SUFFIX (_subprocess_env
    below), so both sides always agree on one namespace name."""
    return f"{question_id}-{user_id}" if user_id else question_id


def _subprocess_env(user_id: Optional[str]) -> Optional[dict]:
    """None (subprocess.run's own default: inherit the parent env unchanged)
    when there's no user_id - byte-for-byte the same environment a
    single-tenant, no-accounts deployment already runs with. Only builds a full env dict (kubectl/
    PATH/etc. must still be there - subprocess.run's `env=` REPLACES the
    environment, it doesn't merge with it) when a suffix actually needs to
    be injected. CLUSTERDRILL_USER_ID is the bare
    user_id, separate from CLUSTERDRILL_NAMESPACE_SUFFIX's leading "-" - setup.sh's
    grant_user_namespace_access call needs the bare id to name the
    ServiceAccount it binds a RoleBinding to, not a namespace suffix."""
    if not user_id:
        return None
    return {**os.environ, "CLUSTERDRILL_NAMESPACE_SUFFIX": f"-{user_id}", "CLUSTERDRILL_USER_ID": user_id}


def parse_check_output(stdout: str) -> tuple[list[Criterion], int, int, str | None]:
    criteria: list[Criterion] = []
    passed_count = 0
    total_count = 0
    found_score = False

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
            passed_count = int(m.group("passed"))
            total_count = int(m.group("total"))
            found_score = True

    error = None if found_score else "no SCORE line found in check.sh output"
    return criteria, passed_count, total_count, error


def run_check(check_sh_path, user_id: Optional[str] = None) -> CheckResult:
    """Runs `bash <check_sh_path>` and parses its stdout per the contract.

    Always shells out for real - this is the only source of truth the
    checklist is allowed to reflect.
    """
    try:
        proc = subprocess.run(
            ["bash", str(check_sh_path)],
            capture_output=True,
            text=True,
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
        proc = subprocess.run(
            ["bash", str(setup_sh_path)],
            capture_output=True,
            text=True,
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
        proc = subprocess.run(
            ["bash", "-c", script, "bash", str(lib_dir / "grading.sh"), *namespaces],
            capture_output=True,
            text=True,
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
        proc = subprocess.run(
            ["bash", "-c", script, "bash", str(lib_dir / "grading.sh"), namespace, str(setup_sh_path)],
            capture_output=True,
            text=True,
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
