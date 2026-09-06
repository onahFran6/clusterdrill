#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q103-38-job-command-args-split-fix${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

pod_succeeded() {
  kubectl wait --for=jsonpath='{.status.phase}'=Succeeded pod/word-counter -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1
}

log_shows_wc_output() {
  kubectl logs word-counter -n "$QUESTION_ID" 2>/dev/null | grep -q "/etc/hostname"
}

check_criterion "Pod 'word-counter' exists in $QUESTION_ID" \
  resource_exists pod word-counter -n "$QUESTION_ID"

check_criterion "Pod 'word-counter' command is exactly [\"wc\"]" \
  [ "$(kget pod word-counter '{.spec.containers[0].command}' -n "$QUESTION_ID")" = '["wc"]' ]

check_criterion "Pod 'word-counter' args are exactly [\"-l\",\"/etc/hostname\"]" \
  [ "$(kget pod word-counter '{.spec.containers[0].args}' -n "$QUESTION_ID")" = '["-l","/etc/hostname"]' ]

check_criterion "Pod 'word-counter' reached phase Succeeded" \
  pod_succeeded

check_criterion "Pod 'word-counter' logs show wc's output for /etc/hostname" \
  log_shows_wc_output

print_score
