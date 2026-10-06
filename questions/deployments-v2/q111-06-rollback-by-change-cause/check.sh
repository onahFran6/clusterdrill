#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q111-06-rollback-by-change-cause${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Running pods use image httpd:2.4.58 (the 'stable release' revision)" \
  bash -c '
    pod="$(newest_pod_name "'"$QUESTION_ID"'" app=billing)"
    [ -n "$pod" ] && [ "$(kubectl get pod "$pod" -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].image}" 2>/dev/null)" = "httpd:2.4.58" ]
  '

check_criterion "Running pods have no CACHE env var (whole revision 2 template restored)" \
  bash -c '
    pod="$(newest_pod_name "'"$QUESTION_ID"'" app=billing)"
    [ -n "$pod" ] || exit 1
    cache="$(kubectl get pod "$pod" -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].env[?(@.name==\"CACHE\")].value}" 2>/dev/null)"
    [ -z "$cache" ]
  '

check_criterion "revisionHistoryLimit is capped to 3" \
  [ "$(kget deployment billing '{.spec.revisionHistoryLimit}' -n "$QUESTION_ID")" = "3" ]

print_score
