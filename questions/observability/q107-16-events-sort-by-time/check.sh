#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q107-16-events-sort-by-time${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Container memory request set to 64Mi" \
  [ "$(kget pod big-mem '{.spec.containers[0].resources.requests.memory}' -n "$QUESTION_ID")" = "64Mi" ]

check_criterion "Container memory limit set to 64Mi" \
  [ "$(kget pod big-mem '{.spec.containers[0].resources.limits.memory}' -n "$QUESTION_ID")" = "64Mi" ]

check_criterion "Pod 'big-mem' phase is Running" \
  [ "$(kget pod big-mem '{.status.phase}' -n "$QUESTION_ID")" = "Running" ]

print_score
