#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q103-46-job-podfailurepolicy-ignore-transient-retry${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Bundled into one criterion. setup.sh already creates a Job named
# heartbeat-sync with the right image/command/backoffLimit, but suspended -
# each of those facts alone would trivially pass before the candidate does
# anything. Gating everything on the Job actually being unsuspended AND
# carrying the Ignore rule AND reaching 1 successful completion keeps the
# unsolved score genuinely 0/1 (a still-suspended Job never reports any
# completions at all).
job_fixed_and_completed() {
  resource_exists job heartbeat-sync -n "$QUESTION_ID" || return 1

  local suspend policy img cmd backoff
  suspend="$(kubectl get job heartbeat-sync -n "$QUESTION_ID" -o jsonpath='{.spec.suspend}' 2>/dev/null)"
  [ "$suspend" != "true" ] || return 1

  policy="$(kubectl get job heartbeat-sync -n "$QUESTION_ID" -o jsonpath='{.spec.podFailurePolicy.rules[0].action}' 2>/dev/null)"
  [ "$policy" = "Ignore" ] || return 1
  local codes
  codes="$(kubectl get job heartbeat-sync -n "$QUESTION_ID" -o jsonpath='{.spec.podFailurePolicy.rules[0].onExitCodes.values[0]}' 2>/dev/null)"
  [ "$codes" = "75" ] || return 1

  backoff="$(kubectl get job heartbeat-sync -n "$QUESTION_ID" -o jsonpath='{.spec.backoffLimit}' 2>/dev/null)"
  [ "$backoff" = "1" ] || return 1

  img="$(kubectl get job heartbeat-sync -n "$QUESTION_ID" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)"
  [ "$img" = "busybox:1.36" ] || return 1

  local pvc
  pvc="$(kubectl get job heartbeat-sync -n "$QUESTION_ID" -o jsonpath='{.spec.template.spec.volumes[0].persistentVolumeClaim.claimName}' 2>/dev/null)"
  [ "$pvc" = "heartbeat-state" ] || return 1

  kubectl wait --for=condition=Complete job/heartbeat-sync -n "$QUESTION_ID" --timeout=150s >/dev/null 2>&1 || return 1
  [ "$(kget job heartbeat-sync '{.status.succeeded}' -n "$QUESTION_ID")" = "1" ]
}

check_criterion "Job 'heartbeat-sync' was recreated unsuspended with a podFailurePolicy Ignore rule for exit code 75, keeps backoffLimit=1 and its image/PVC, and reports 1 successful completion" \
  job_fixed_and_completed

print_score
