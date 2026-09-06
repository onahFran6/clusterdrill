#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q103-45-cronjob-schedule-step-value-every-5-minutes${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "CronJob 'metrics-poll' exists in $QUESTION_ID" \
  resource_exists cronjob metrics-poll -n "$QUESTION_ID"

check_criterion "CronJob 'metrics-poll' schedule is '*/5 * * * *' (step-value syntax)" \
  [ "$(kget cronjob metrics-poll '{.spec.schedule}' -n "$QUESTION_ID")" = "*/5 * * * *" ]

check_criterion "CronJob 'metrics-poll' jobTemplate uses image busybox:1.36, command 'echo polling', restartPolicy Never" \
  bash -c '
    NS="'"$QUESTION_ID"'"
    img="$(kubectl get cronjob metrics-poll -n "$NS" -o jsonpath="{.spec.jobTemplate.spec.template.spec.containers[0].image}" 2>/dev/null)"
    [ "$img" = "busybox:1.36" ] || exit 1
    cmd="$(kubectl get cronjob metrics-poll -n "$NS" -o jsonpath="{.spec.jobTemplate.spec.template.spec.containers[0].command}" 2>/dev/null)"
    [ "$cmd" = "[\"echo\",\"polling\"]" ] || exit 1
    rp="$(kubectl get cronjob metrics-poll -n "$NS" -o jsonpath="{.spec.jobTemplate.spec.template.spec.restartPolicy}" 2>/dev/null)"
    [ "$rp" = "Never" ]
  '

print_score
