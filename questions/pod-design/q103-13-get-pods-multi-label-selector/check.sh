#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q103-13-get-pods-multi-label-selector${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

only_correct_pod_verified() {
  local verified_count
  verified_count="$(kubectl get pods -n "$QUESTION_ID" -l verified=true --no-headers 2>/dev/null | wc -l | tr -d ' ')"
  [ "$verified_count" = "1" ]
}

check_criterion "Pod 'frontend-a' is labeled verified=true" \
  [ "$(kget pod frontend-a '{.metadata.labels.verified}' -n "$QUESTION_ID")" = "true" ]

check_criterion "No other pod is labeled verified=true" \
  only_correct_pod_verified

print_score
