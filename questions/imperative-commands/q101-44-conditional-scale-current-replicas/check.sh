#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q101-44-conditional-scale-current-replicas${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'queue-consumer' has spec.replicas=5" \
  [ "$(kget deployment queue-consumer '{.spec.replicas}' -n "$QUESTION_ID")" = "5" ]

deployment_at_five() {
  local i ready
  for ((i = 0; i < 20; i++)); do
    ready="$(kget deployment queue-consumer '{.status.readyReplicas}' -n "$QUESTION_ID")"
    if [ "$ready" = "5" ]; then
      return 0
    fi
    sleep 3
  done
  return 1
}
check_criterion "Deployment 'queue-consumer' actually reaches 5 ready replicas" \
  deployment_at_five

print_score
