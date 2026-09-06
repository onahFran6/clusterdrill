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

from grading_client import _subprocess_env, namespaced_id, parse_check_output


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
    stdout = "  CRITERION:   pod exists   =   PASS  \nSCORE:   3  /  3  "
    criteria, passed, total, error = parse_check_output(stdout)
    assert error is None
    assert criteria[0].description == "pod exists"
    assert passed == 3
    assert total == 3


def test_score_line_wins_even_if_last():
    # Contract says SCORE is the last line - confirm a second/duplicate
    # SCORE-shaped line further down still just overwrites (parser doesn't
    # need to defend against malformed check.sh scripts beyond "don't
    # crash"), matching parse_check_output's simple last-wins loop.
    stdout = "SCORE: 1/2\nCRITERION: x = FAIL\nSCORE: 2/2"
    criteria, passed, total, error = parse_check_output(stdout)
    assert error is None
    assert passed == 2
    assert total == 2


# --- namespaced_id / _subprocess_env ----------------------------------

def test_namespaced_id_bare_question_id_without_user():
    assert namespaced_id("q105-18-secret-volume-default-mode", None) == "q105-18-secret-volume-default-mode"


def test_namespaced_id_suffixes_with_user_id():
    assert namespaced_id("q105-18-secret-volume-default-mode", "alice") == "q105-18-secret-volume-default-mode-alice"


def test_subprocess_env_none_without_user_id():
    # subprocess.run(env=None) inherits the parent process's environment
    # unchanged - the exact behavior for a no-accounts deployment.
    assert _subprocess_env(None) is None


def test_subprocess_env_injects_suffix_and_preserves_existing_vars():
    os.environ["CLUSTERDRILL_GRADING_CLIENT_TEST_SENTINEL"] = "still-here"
    try:
        env = _subprocess_env("alice")
        assert env["CLUSTERDRILL_NAMESPACE_SUFFIX"] == "-alice"
        assert env["CLUSTERDRILL_GRADING_CLIENT_TEST_SENTINEL"] == "still-here"
    finally:
        del os.environ["CLUSTERDRILL_GRADING_CLIENT_TEST_SENTINEL"]


def test_subprocess_env_injects_bare_user_id():
    # Separate from CLUSTERDRILL_NAMESPACE_SUFFIX's leading "-" - lib/grading.sh's
    # grant_user_namespace_access needs the bare id to name the
    # ServiceAccount subject it binds, not a namespace suffix.
    env = _subprocess_env("alice")
    assert env["CLUSTERDRILL_USER_ID"] == "alice"
