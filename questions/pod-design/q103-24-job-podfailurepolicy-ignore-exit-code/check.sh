#!/usr/bin/env bash
# Grades ONLY live cluster state - never a client-supplied "done" flag.
# No `set -e` on purpose: check_criterion returning non-zero on a FAIL is
# normal, not a script error.
set -uo pipefail

QUESTION_ID="q103-24-job-podfailurepolicy-ignore-exit-code${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

job_failed_reason() {
  local job="$1"
  kget job "$job" '{.status.conditions[?(@.type=="Failed")].reason}' -n "$QUESTION_ID"
}

# pod_count scopes strictly to pods owned by the CURRENTLY-live Job object
# (matched by its .metadata.uid via the controller-uid label), not just its
# name. A plain job-name selector would also match leftover pods from a
# just-deleted same-named Job instance still being garbage-collected (the
# reference answer deletes+recreates both Jobs, since podFailurePolicy is
# immutable) - a real race observed empirically that inflates the count by
# one and produces a false FAIL right after the fix is applied.
pod_count() {
  local job="$1"
  local uid
  uid="$(kget job "$job" '{.metadata.uid}' -n "$QUESTION_ID")"
  [ -z "$uid" ] && { echo 0; return; }
  kubectl get pods -n "$QUESTION_ID" -l "controller-uid=$uid" --no-headers 2>/dev/null | wc -l | tr -d ' '
}

# code42-loader must fail the Job immediately (via podFailurePolicy's
# FailJob action matching exit code 42) after exactly ONE pod - not retry.
# Bounded, live-behavior poll: a correctly-configured Job reaches Failed
# with reason PodFailurePolicy and pod count 1 within ~10s (observed
# empirically); an unfixed Job either has no matching Failed condition yet
# after a second pod is already running (proving it retried the "terminal"
# exit code - wrong), or eventually fails for some other reason entirely
# (e.g. BackoffLimitExceeded once backoffLimit is exhausted - also wrong).
# Either wrong outcome is detected and short-circuited as soon as it's
# observed, so this never needs to sit through the full timeout to fail.
code42_loader_fails_fast() {
  resource_exists job code42-loader -n "$QUESTION_ID" || return 1
  local waited=0 reason count
  while [ "$waited" -lt 90 ]; do
    reason="$(job_failed_reason code42-loader)"
    count="$(pod_count code42-loader)"
    if [ -n "$reason" ]; then
      [ "$reason" = "PodFailurePolicy" ] && [ "$count" = "1" ]
      return $?
    fi
    if [ -n "$count" ] && [ "$count" -ge 2 ] 2>/dev/null; then
      # A second pod exists but the Job still hasn't failed - the exit-42
      # pod is being retried instead of failing the Job immediately.
      return 1
    fi
    sleep 3
    waited=$((waited + 3))
  done
  return 1
}

# flaky-loader must NOT be terminated by podFailurePolicy on its first
# failure - it must retry like a normal Job up to backoffLimit=2 (1 initial
# attempt + 2 retries = 3 pods total, matching this bank's other
# backoffLimit questions), and only then fail with reason
# BackoffLimitExceeded. Bounded, live-behavior poll: correctly-configured
# takes ~35-40s to observe 3 pods + BackoffLimitExceeded (empirically
# measured); a still-too-broad policy fails the Job within seconds via
# reason PodFailurePolicy, which is terminal (the Job never creates more
# pods afterwards) so that wrong outcome is detected and returned
# immediately instead of waiting out the full timeout.
flaky_loader_retries_normally() {
  resource_exists job flaky-loader -n "$QUESTION_ID" || return 1
  local waited=0 reason count
  while [ "$waited" -lt 120 ]; do
    reason="$(job_failed_reason flaky-loader)"
    if [ -n "$reason" ]; then
      count="$(pod_count flaky-loader)"
      [ "$reason" = "BackoffLimitExceeded" ] && [ "$count" = "3" ]
      return $?
    fi
    sleep 5
    waited=$((waited + 5))
  done
  return 1
}

check_criterion "Job 'code42-loader' fails immediately on exit code 42 (podFailurePolicy FailJob, no retries)" \
  code42_loader_fails_fast

check_criterion "Job 'flaky-loader' still retries normally to backoffLimit on non-42 exit codes" \
  flaky_loader_retries_normally

print_score
