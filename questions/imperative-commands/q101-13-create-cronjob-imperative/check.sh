#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q101-13-create-cronjob-imperative${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "CronJob 'heartbeat' exists in $QUESTION_ID" \
  resource_exists cronjob heartbeat -n "$QUESTION_ID"

check_criterion "CronJob 'heartbeat' uses image 'busybox:1.36'" \
  [ "$(kget cronjob heartbeat '{.spec.jobTemplate.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

check_criterion "CronJob 'heartbeat' schedule is '*/5 * * * *'" \
  [ "$(kget cronjob heartbeat '{.spec.schedule}' -n "$QUESTION_ID")" = "*/5 * * * *" ]

check_criterion "CronJob 'heartbeat' command includes 'echo heartbeat'" \
  bash -c "kubectl get cronjob heartbeat -n '$QUESTION_ID' -o jsonpath='{.spec.jobTemplate.spec.template.spec.containers[0].args[*]}{.spec.jobTemplate.spec.template.spec.containers[0].command[*]}' 2>/dev/null | grep -q 'echo heartbeat'"

print_score
