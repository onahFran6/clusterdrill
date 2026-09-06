#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q107-14-deprecated-apiversion-fix${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "CronJob 'nightly-cleanup' exists in $QUESTION_ID" \
  resource_exists cronjob nightly-cleanup -n "$QUESTION_ID"

check_criterion "CronJob uses the current batch/v1 API group" \
  [ "$(kubectl get cronjob nightly-cleanup -n "$QUESTION_ID" -o jsonpath='{.apiVersion}' 2>/dev/null)" = "batch/v1" ]

check_criterion "CronJob schedule is '0 2 * * *'" \
  [ "$(kget cronjob nightly-cleanup '{.spec.schedule}' -n "$QUESTION_ID")" = "0 2 * * *" ]

check_criterion "CronJob's container uses image busybox:1.36" \
  [ "$(kget cronjob nightly-cleanup '{.spec.jobTemplate.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

print_score
