"""grading_client.parse_check_output: pure regex/string parsing against
check.sh's stdout contract (lib/grading.sh) - zero I/O, zero subprocess.
This is the grading-integrity invariant's parsing half, worth pinning down precisely.

Also covers namespaced_id/_subprocess_env -
pure string/dict logic, same "no subprocess" scope as the rest of this
file; run_check/run_setup/run_reset/run_batch_cleanup's actual subprocess
plumbing is exercised at the route level (tests/routes/), always mocked.
"""
from __future__ import annotations

import os
import subprocess
import time

import pytest
import users
from grading_client import _run_subprocess, _subprocess_env, namespaced_id, parse_check_output


def test_all_pass():
    stdout = "\n".join([
        "CRITERION: pod exists = PASS",
        "CRITERION: pod is running = PASS",
        "SCORE: 2/2",
    ])
    criteria, passed, total, error = parse_check_output(stdout)
    assert error is None
    assert passed == 2
    assert total == 2
    assert [c.passed for c in criteria] == [True, True]
    assert [c.description for c in criteria] == ["pod exists", "pod is running"]


def test_mixed_pass_fail():
    stdout = "\n".join([
        "CRITERION: configmap exists = PASS",
        "CRITERION: volume mounted correctly = FAIL",
        "SCORE: 1/2",
    ])
    criteria, passed, total, error = parse_check_output(stdout)
    assert error is None
    assert passed == 1
    assert total == 2
    assert criteria[0].passed is True
    assert criteria[1].passed is False


def test_missing_score_line_is_an_error():
    stdout = "CRITERION: pod exists = PASS\n"
    criteria, passed, total, error = parse_check_output(stdout)
    assert error == "no SCORE line found in check.sh output"
    assert passed == 0
    assert total == 0
    # Criteria lines before the missing SCORE line are still parsed - the
    # error is specifically "no authoritative score", not "nothing parsed".
    assert len(criteria) == 1


def test_empty_output_is_an_error():
    criteria, passed, total, error = parse_check_output("")
    assert error is not None
    assert criteria == []
    assert passed == 0
    assert total == 0


def test_ignores_unrelated_stdout_noise():
    # check.sh may print kubectl output, warnings, etc. around the
    # contract lines - the parser must only key off the exact CRITERION:/
    # SCORE: line shapes, not fail on anything else present.
    stdout = "\n".join([
        "Waiting for pod to be ready...",
        "pod/nginx condition met",
        "CRITERION: pod exists = PASS",
        "some random debug line",
        "SCORE: 1/1",
    ])
    criteria, passed, total, error = parse_check_output(stdout)
    assert error is None
    assert passed == 1
    assert total == 1
    assert len(criteria) == 1


def test_whitespace_tolerant():
    stdout = "\n".join([
        "  CRITERION:   pod exists   =   PASS  ",
        "  CRITERION:   pod ready   =   PASS  ",
        "  CRITERION:   pod healthy   =   PASS  ",
        "SCORE:   3  /  3  ",
    ])
    criteria, passed, total, error = parse_check_output(stdout)
    assert error is None
    assert criteria[0].description == "pod exists"
    assert passed == 3
    assert total == 3


def test_duplicate_score_line_is_an_error():
    # A legitimate check.sh prints exactly one SCORE line (lib/grading.sh's
    # print_score is always the last line a script calls) - two SCORE-shaped
    # lines means something is wrong with the script, not a value to
    # silently overwrite and trust (R12).
    stdout = "SCORE: 1/2\nCRITERION: x = FAIL\nSCORE: 2/2"
    criteria, passed, total, error = parse_check_output(stdout)
    assert error == "duplicate SCORE line in check.sh output"


def test_score_exceeding_total_is_an_error():
    stdout = "CRITERION: x = PASS\nSCORE: 5/1"
    criteria, passed, total, error = parse_check_output(stdout)
    assert error is not None
    assert "impossible SCORE" in error


def test_score_inconsistent_with_criteria_is_an_error():
    # A checker that claims 2/2 but only printed one CRITERION line (or one
    # that printed three PASS/FAIL lines but a SCORE of 1/1) is lying about
    # its own output, whether or not it exited 0.
    stdout = "CRITERION: x = PASS\nSCORE: 2/2"
    criteria, passed, total, error = parse_check_output(stdout)
    assert error is not None
    assert "does not match" in error


# --- _run_subprocess: whole-process-group teardown on timeout (I05) --------

def test_run_subprocess_kills_grandchild_on_timeout(tmp_path):
    # A bash script that backgrounds a long-running grandchild (not bash
    # itself) and writes its PID out - the exact shape of a real
    # check.sh/setup.sh that spawns kubectl in the background. A bare
    # subprocess.run(timeout=...) only ever signals the immediate `bash`
    # child, leaving a grandchild like this one to keep running unsupervised
    # (I05); _run_subprocess must kill the whole process group instead.
    pid_file = tmp_path / "child.pid"
    script = f"sleep 30 & echo $! > {pid_file}; wait"

    with pytest.raises(subprocess.TimeoutExpired):
        _run_subprocess(["bash", "-c", script], timeout=1)

    child_pid = int(pid_file.read_text().strip())
    time.sleep(0.2)  # give the signal a moment to land
    with pytest.raises(ProcessLookupError):
        os.kill(child_pid, 0)  # signal 0: raises iff the pid is gone


# --- namespaced_id / _subprocess_env ----------------------------------
#
# single_user_mode() is permanently True in the live app (R08/Proposal A):
# there is structurally only ever one operator, so namespaced_id/
# _subprocess_env never suffix anything regardless of user_id. The
# "_still_suffixes_if_not_single_user" tests below monkeypatch
# single_user_mode() back to False to pin down the underlying per-user-
# suffix mechanism's own correctness, the same way test_ttyd_manager.py/
# test_users.py cover retained-but-unreachable per-user code paths.

def test_namespaced_id_bare_question_id_without_user():
    assert namespaced_id("q105-18-secret-volume-default-mode", None) == "q105-18-secret-volume-default-mode"


def test_namespaced_id_ignores_user_id_in_single_user_mode():
    assert namespaced_id("q105-18-secret-volume-default-mode", "alice") == "q105-18-secret-volume-default-mode"


def test_namespaced_id_still_suffixes_if_not_single_user(monkeypatch):
    monkeypatch.setattr(users, "single_user_mode", lambda: False)
    assert namespaced_id("q105-18-secret-volume-default-mode", "alice") == "q105-18-secret-volume-default-mode-alice"


def test_subprocess_env_none_without_user_id():
    # subprocess.run(env=None) inherits the parent process's environment
    # unchanged - the exact behavior for a no-accounts deployment.
    assert _subprocess_env(None) is None


def test_subprocess_env_none_in_single_user_mode_even_with_user_id():
    assert _subprocess_env("alice") is None


def test_subprocess_env_still_injects_suffix_if_not_single_user(monkeypatch):
    monkeypatch.setattr(users, "single_user_mode", lambda: False)
    os.environ["CLUSTERDRILL_GRADING_CLIENT_TEST_SENTINEL"] = "still-here"
    try:
        env = _subprocess_env("alice")
        assert env["CLUSTERDRILL_NAMESPACE_SUFFIX"] == "-alice"
        assert env["CLUSTERDRILL_GRADING_CLIENT_TEST_SENTINEL"] == "still-here"
    finally:
        del os.environ["CLUSTERDRILL_GRADING_CLIENT_TEST_SENTINEL"]


def test_subprocess_env_still_injects_bare_user_id_if_not_single_user(monkeypatch):
    # Separate from CLUSTERDRILL_NAMESPACE_SUFFIX's leading "-" - lib/grading.sh's
    # grant_user_namespace_access needs the bare id to name the
    # ServiceAccount subject it binds, not a namespace suffix.
    monkeypatch.setattr(users, "single_user_mode", lambda: False)
    env = _subprocess_env("alice")
    assert env["CLUSTERDRILL_USER_ID"] == "alice"
