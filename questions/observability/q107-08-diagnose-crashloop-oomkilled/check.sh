#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q107-08-diagnose-crashloop-oomkilled${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Container memory limit raised to 256Mi" \
  [ "$(kget pod render-worker '{.spec.containers[0].resources.limits.memory}' -n "$QUESTION_ID")" = "256Mi" ]

check_criterion "Container memory request set to 256Mi" \
  [ "$(kget pod render-worker '{.spec.containers[0].resources.requests.memory}' -n "$QUESTION_ID")" = "256Mi" ]

check_criterion "Pod 'render-worker' phase is Running" \
  [ "$(kget pod render-worker '{.status.phase}' -n "$QUESTION_ID")" = "Running" ]

check_criterion "Pod 'render-worker' container is Ready" \
  [ "$(kget pod render-worker '{.status.containerStatuses[0].ready}' -n "$QUESTION_ID")" = "true" ]

print_score
