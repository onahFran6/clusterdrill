#!/usr/bin/env bash
# Grades ONLY live cluster state - never a client-supplied "done" flag.
#
# No `set -e` here on purpose: check_criterion returns non-zero on a FAIL,
# which is a normal, expected result per criterion, not a script error.
set -uo pipefail

QUESTION_ID="q103-27-job-activedeadline-interrupts-backoff${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Everything is bundled into ONE criterion on purpose. The Job, its image,
# command, and backoffLimit are all already true immediately after setup.sh
# (before the candidate touches anything) - only activeDeadlineSeconds
# changes. Checking any of those pre-existing facts as their own separate
# check_criterion would already be true on the unsolved state and break the
# required "0/N on unsolved" gate, so the one thing that actually changes
# (activeDeadlineSeconds) and the one thing that only becomes true because
# of it (the Job actually failing with reason DeadlineExceeded, not
# BackoffLimitExceeded) are graded together as a single pass/fail.
#
# The activeDeadlineSeconds check runs first and fails fast (no waiting) on
# the unsolved state, since setup.sh ships the wrong value (90). Only once
# the value is correct do we pay the cost of waiting for the Job to actually
# reach a terminal state.
job_deadline_interrupts_backoff() {
  [ "$(kget job stubborn-retrier '{.spec.activeDeadlineSeconds}' -n "$QUESTION_ID")" = "25" ] || return 1

  kubectl wait --for=condition=Failed job/stubborn-retrier -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1 || return 1

  [ "$(kget job stubborn-retrier '{.status.conditions[?(@.type=="Failed")].reason}' -n "$QUESTION_ID")" = "DeadlineExceeded" ]
}

check_criterion "Job 'stubborn-retrier' activeDeadlineSeconds=25 interrupts the retry sequence with reason DeadlineExceeded (not BackoffLimitExceeded)" \
  job_deadline_interrupts_backoff

print_score
