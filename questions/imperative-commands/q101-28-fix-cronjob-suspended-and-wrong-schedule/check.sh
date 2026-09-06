#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q101-28-fix-cronjob-suspended-and-wrong-schedule${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# setup.sh already leaves spec.suspend=true on a schedule that can never
# fire (Feb 31st). Neither "suspend is false" nor "schedule looks valid"
# alone would be enough to gate scoring, since a candidate could fix only
# one and the other criterion would still correctly fail - but to be extra
# safe against the "already true before any fix" gate, bundle both flips
# into one criterion so nothing scores until BOTH problems are fixed.
check_criterion "CronJob 'log-rotator' is unsuspended AND has a valid, non-Feb-31st schedule" \
  bash -c '
    [ "$(kubectl get cronjob log-rotator -o jsonpath="{.spec.suspend}" -n "'"$QUESTION_ID"'" 2>/dev/null)" = "false" ] || exit 1
    schedule=$(kubectl get cronjob log-rotator -o jsonpath="{.spec.schedule}" -n "'"$QUESTION_ID"'" 2>/dev/null)
    [ -n "$schedule" ] || exit 1
    [ "$schedule" != "0 0 31 2 *" ] || exit 1
    field="[0-9*/,-]+"
    echo "$schedule" | grep -Eq "^$field[[:space:]]+$field[[:space:]]+$field[[:space:]]+$field[[:space:]]+$field\$"
  '

check_criterion "Container image/command on 'log-rotator' were left untouched" \
  bash -c '
    [ "$(kubectl get cronjob log-rotator -o jsonpath="{.spec.jobTemplate.spec.template.spec.containers[0].image}" -n "'"$QUESTION_ID"'" 2>/dev/null)" = "busybox:1.36" ] &&
    [ "$(kubectl get cronjob log-rotator -o jsonpath="{.spec.suspend}" -n "'"$QUESTION_ID"'" 2>/dev/null)" = "false" ]
  '

# The real proof the fix works end-to-end: a Job actually owned by
# log-rotator gets created (by the fixed, unsuspended schedule) and one of
# its pods runs to completion - not just that the spec fields look right.
# Poll for up to 3 minutes since the candidate's own schedule choice
# determines how long this takes.
a_job_owned_by_log_rotator_completes() {
  local i job pod phase
  for ((i = 0; i < 90; i++)); do
    job="$(kubectl get jobs -n "$QUESTION_ID" \
      -o jsonpath='{range .items[?(@.metadata.ownerReferences[0].name=="log-rotator")]}{.metadata.name}{"\n"}{end}' \
      2>/dev/null | head -n1)"
    if [ -n "$job" ]; then
      pod="$(kubectl get pods -n "$QUESTION_ID" -l "job-name=$job" \
        -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.status.phase}{"\n"}{end}' 2>/dev/null \
        | grep -m1 'Succeeded')"
      if [ -n "$pod" ]; then
        return 0
      fi
    fi
    sleep 2
  done
  return 1
}
check_criterion "A Job owned by 'log-rotator' has a completed (Succeeded) pod" \
  a_job_owned_by_log_rotator_completes

print_score
