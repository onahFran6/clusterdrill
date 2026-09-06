#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q103-04-job-restart-policy-onfailure${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# #35: the job controller itself DELETES the pod the moment backoffLimit
# is exceeded for a restartPolicy: OnFailure Job (confirmed live - a
# "SuccessfulDelete" job-controller event fires right alongside
# "BackoffLimitExceeded", since kubelet would otherwise keep restarting
# the container in that pod forever, ignoring backoffLimit entirely at
# the container level - the controller's only way to actually "give up"
# is to delete the pod). A pod-count snapshot taken *after* waiting for
# Failed therefore always sees zero pods for a correct answer, not one -
# the previous version of this check scored a correct reference answer
# 4/5. Fixed by tracking every distinct pod name seen *during* the same
# poll that waits for Failed, not counting whatever's left afterward -
# this still correctly catches the actual mistake this criterion exists
# to catch (restartPolicy: Never on the pod template, which creates a
# brand-new pod object per retry instead of restarting the same pod's
# container in place - those pods stay far longer and are trivially
# multiple distinct names).
_JOB_FAILED=false
_POD_NAMES_SEEN=""

poll_job_completion_tracking_pod_names() {
  if ! resource_exists job retry-in-place -n "$QUESTION_ID"; then
    return
  fi
  local i cond names
  for ((i = 0; i < 90; i++)); do
    names="$(kubectl get pods -n "$QUESTION_ID" -l job-name=retry-in-place \
      -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null)"
    if [ -n "$names" ]; then
      _POD_NAMES_SEEN="$(printf '%s\n%s\n' "$_POD_NAMES_SEEN" "$names")"
    fi
    cond="$(kget job retry-in-place '{.status.conditions[?(@.type=="Failed")].status}' -n "$QUESTION_ID")"
    if [ "$cond" = "True" ]; then
      _JOB_FAILED=true
      break
    fi
    sleep 2
  done
}

check_criterion "Job 'retry-in-place' exists in $QUESTION_ID" \
  resource_exists job retry-in-place -n "$QUESTION_ID"

check_criterion "Job 'retry-in-place' pod template uses restartPolicy: OnFailure" \
  [ "$(kget job retry-in-place '{.spec.template.spec.restartPolicy}' -n "$QUESTION_ID")" = "OnFailure" ]

check_criterion "Job 'retry-in-place' backoffLimit is set to 3" \
  [ "$(kget job retry-in-place '{.spec.backoffLimit}' -n "$QUESTION_ID")" = "3" ]

poll_job_completion_tracking_pod_names
unique_pod_count="$(echo "$_POD_NAMES_SEEN" | sed '/^[[:space:]]*$/d' | sort -u | wc -l | tr -d ' ')"

check_criterion "Job 'retry-in-place' reaches Failed after exhausting retries" \
  [ "$_JOB_FAILED" = "true" ]

check_criterion "Job 'retry-in-place' only ever created a single pod" \
  [ "$unique_pod_count" = "1" ]

print_score
