#!/usr/bin/env bash
# Grades ONLY live cluster state - never a client-supplied "done" flag.
#
# No `set -e` here on purpose: check_criterion returns non-zero on a FAIL,
# which is a normal, expected result per criterion, not a script error.
set -uo pipefail

QUESTION_ID="q101-34-extract-pod-spec-into-cronjob${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# setup.sh never creates a CronJob at all - only the source Pod
# 'legacy-report-gen' - so every one of these criteria is impossible to
# pass on the unsolved state; none needs bundling with a pre-true condition.

check_criterion "CronJob 'report-job' exists in $QUESTION_ID" \
  resource_exists cronjob report-job -n "$QUESTION_ID"

check_criterion "CronJob 'report-job' schedule is '*/5 * * * *'" \
  [ "$(kget cronjob report-job '{.spec.schedule}' -n "$QUESTION_ID")" = "*/5 * * * *" ]

check_criterion "CronJob 'report-job' container image matches the source pod ('busybox:1.36')" \
  [ "$(kget cronjob report-job '{.spec.jobTemplate.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

env_vars_match_source_pod() {
  local report_type output_path retry_limit
  report_type="$(kubectl get cronjob report-job -n "$QUESTION_ID" \
    -o jsonpath='{.spec.jobTemplate.spec.template.spec.containers[0].env[?(@.name=="REPORT_TYPE")].value}' 2>/dev/null)"
  output_path="$(kubectl get cronjob report-job -n "$QUESTION_ID" \
    -o jsonpath='{.spec.jobTemplate.spec.template.spec.containers[0].env[?(@.name=="OUTPUT_PATH")].value}' 2>/dev/null)"
  retry_limit="$(kubectl get cronjob report-job -n "$QUESTION_ID" \
    -o jsonpath='{.spec.jobTemplate.spec.template.spec.containers[0].env[?(@.name=="RETRY_LIMIT")].value}' 2>/dev/null)"
  [ "$report_type" = "weekly" ] && [ "$output_path" = "/var/reports/output.txt" ] && [ "$retry_limit" = "5" ]
}
check_criterion "CronJob 'report-job' env vars (REPORT_TYPE, OUTPUT_PATH, RETRY_LIMIT) match the source pod exactly" \
  env_vars_match_source_pod

command_matches_source_pod() {
  local c0 c1 c2
  c0="$(kget cronjob report-job '{.spec.jobTemplate.spec.template.spec.containers[0].command[0]}' -n "$QUESTION_ID")"
  c1="$(kget cronjob report-job '{.spec.jobTemplate.spec.template.spec.containers[0].command[1]}' -n "$QUESTION_ID")"
  c2="$(kget cronjob report-job '{.spec.jobTemplate.spec.template.spec.containers[0].command[2]}' -n "$QUESTION_ID")"
  [ "$c0" = "sh" ] || return 1
  [ "$c1" = "-c" ] || return 1
  [ "$c2" = 'echo Report type=$REPORT_TYPE output=$OUTPUT_PATH retries=$RETRY_LIMIT && sleep 3600' ]
}
check_criterion "CronJob 'report-job' command matches the source pod's exact command" \
  command_matches_source_pod

print_score
