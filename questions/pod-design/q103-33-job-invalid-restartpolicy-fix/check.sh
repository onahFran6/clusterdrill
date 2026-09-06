#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q103-33-job-invalid-restartpolicy-fix${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

job_ran_once_successfully() {
  kubectl wait --for=condition=Complete job/broken-once -n "$QUESTION_ID" --timeout=90s >/dev/null 2>&1 || return 1
  [ "$(kget job broken-once '{.status.succeeded}' -n "$QUESTION_ID")" = "1" ]
}

check_criterion "Job 'broken-once' exists in $QUESTION_ID" \
  resource_exists job broken-once -n "$QUESTION_ID"

check_criterion "Job 'broken-once' uses a valid restartPolicy (Never or OnFailure)" \
  bash -c '
    rp="$(kubectl get job broken-once -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.restartPolicy}" 2>/dev/null)"
    [ "$rp" = "Never" ] || [ "$rp" = "OnFailure" ]
  '

check_criterion "Job 'broken-once' keeps image busybox:1.36 and command 'echo done'" \
  bash -c '
    img="$(kubectl get job broken-once -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    [ "$img" = "busybox:1.36" ] || exit 1
    cmd="$(kubectl get job broken-once -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].command}" 2>/dev/null)"
    [ "$cmd" = "[\"echo\",\"done\"]" ]
  '

check_criterion "Job 'broken-once' completed successfully exactly once" \
  job_ran_once_successfully

print_score
