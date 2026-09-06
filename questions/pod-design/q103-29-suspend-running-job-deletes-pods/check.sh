#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e` on purpose - check_criterion
# returning non-zero on a FAIL is expected, not a script error.
set -uo pipefail

QUESTION_ID="q103-29-suspend-running-job-deletes-pods${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
JOB_NAME="report-builder"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# setup.sh already creates the Job with a genuinely Running pod - "Job
# exists" and "pod is Running" are both trivially true immediately after
# setup.sh, before the candidate has done anything. Per the bank's
# recurring-bug fix, everything trivially-true is folded into the SAME
# criterion as the one thing that actually has to change (suspend flipping
# to true, which then deletes the running pod), so there is exactly one
# scored criterion below.
job_suspended_with_pods_deleted() {
  resource_exists job "$JOB_NAME" -n "$QUESTION_ID" || return 1

  local suspend
  suspend="$(kget job "$JOB_NAME" '{.spec.suspend}' -n "$QUESTION_ID")"

  if [ "$suspend" != "true" ]; then
    # Not suspended yet (the unsolved state, or any state where the
    # candidate hasn't flipped suspend). Confirm the environment really is
    # what the task claims - the Job's pod genuinely reached Running - as a
    # sanity check on setup.sh's own seed state, then fail this criterion
    # regardless: suspend must become true for it to ever pass.
    kubectl wait pod -n "$QUESTION_ID" -l "job-name=$JOB_NAME" \
      --for=jsonpath='{.status.phase}'=Running --timeout=60s >/dev/null 2>&1
    return 1
  fi

  # Suspended. A just-deleted pod can sit Terminating with .status.phase
  # still Running for a few seconds, so poll for a STABLE zero-pod count
  # (two consecutive zero reads) rather than trusting a single snapshot.
  local count zero_streak=0 attempt
  for attempt in $(seq 1 30); do
    count="$(kubectl get pods -n "$QUESTION_ID" -l "job-name=$JOB_NAME" \
      --no-headers 2>/dev/null | wc -l | tr -d ' ')"
    if [ "$count" = "0" ]; then
      zero_streak=$((zero_streak + 1))
      [ "$zero_streak" -ge 2 ] && break
    else
      zero_streak=0
    fi
    sleep 1
  done
  [ "$zero_streak" -ge 2 ] || return 1

  # status.active is omitted entirely once there are no active pods, so
  # both "absent" and the literal string "0" count as zero.
  local active
  active="$(kget job "$JOB_NAME" '{.status.active}' -n "$QUESTION_ID")"
  [ -z "$active" ] || [ "$active" = "0" ]
}

check_criterion "Job '$JOB_NAME' is suspended (spec.suspend=true) and its previously-running pod was deleted (0 pods, status.active=0)" \
  job_suspended_with_pods_deleted

print_score
