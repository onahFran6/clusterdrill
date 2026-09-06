#!/usr/bin/env bash
# Grades ONLY live cluster state - never a client-supplied "done" flag.
#
# Both criteria below are FALSE immediately after setup.sh (the whole point
# of the missing RBAC grant), so neither is a trivially-true false positive
# in the unsolved state: "SA can patch" requires the fix, and "a fresh run
# completes and updates job-status" requires the fix too (the 403 rejection
# makes the container exit non-zero, so the Job stays Failed).
#
# No `set -e` here on purpose - check_criterion returns non-zero on a FAIL,
# a normal expected result per criterion, not a script error.
set -uo pipefail

QUESTION_ID="q103-30-cronjob-needs-rbac-to-complete-task${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

SA_SUBJECT="system:serviceaccount:${QUESTION_ID}:status-recorder-sa"

sa_can_patch_configmap() {
  kubectl auth can-i patch configmap/job-status \
    --as="$SA_SUBJECT" -n "$QUESTION_ID" 2>/dev/null | grep -q '^yes'
}

# Triggers a brand-new Job from the CronJob's template (fresh name every
# call, so re-running check.sh never collides with a prior attempt), then
# polls for a terminal state instead of taking one snapshot - a just-
# created Job's pod can sit briefly before its condition settles.
trigger_and_verify_run() {
  local job_name="status-recorder-check-$(date +%s)-$$"

  kubectl create job "$job_name" --from="cronjob/status-recorder" -n "$QUESTION_ID" >/dev/null 2>&1 \
    || return 1

  local attempt
  for attempt in $(seq 1 30); do
    if kubectl get job "$job_name" -n "$QUESTION_ID" \
      -o jsonpath='{.status.conditions[?(@.type=="Complete")].status}' 2>/dev/null | grep -q True; then
      break
    fi
    if kubectl get job "$job_name" -n "$QUESTION_ID" \
      -o jsonpath='{.status.conditions[?(@.type=="Failed")].status}' 2>/dev/null | grep -q True; then
      return 1
    fi
    sleep 2
  done

  kubectl get job "$job_name" -n "$QUESTION_ID" \
    -o jsonpath='{.status.conditions[?(@.type=="Complete")].status}' 2>/dev/null | grep -q True \
    || return 1

  local recorded_status
  recorded_status="$(kget configmap job-status '{.data.last_run_status}' -n "$QUESTION_ID")"
  [ -n "$recorded_status" ] && [ "$recorded_status" != "never-run" ]
}

check_criterion "ServiceAccount 'status-recorder-sa' is authorized to patch ConfigMap 'job-status'" \
  sa_can_patch_configmap

check_criterion "A freshly triggered run of CronJob 'status-recorder' completes and updates job-status's last_run_status" \
  trigger_and_verify_run

print_score
