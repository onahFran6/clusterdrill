#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q101-19-run-pod-resource-limits${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'sized-app' exists in $QUESTION_ID" \
  resource_exists pod sized-app -n "$QUESTION_ID"

check_criterion "Pod 'sized-app' requests cpu=100m" \
  [ "$(kget pod sized-app '{.spec.containers[0].resources.requests.cpu}' -n "$QUESTION_ID")" = "100m" ]

check_criterion "Pod 'sized-app' requests memory=64Mi" \
  [ "$(kget pod sized-app '{.spec.containers[0].resources.requests.memory}' -n "$QUESTION_ID")" = "64Mi" ]

check_criterion "Pod 'sized-app' limits cpu=250m" \
  [ "$(kget pod sized-app '{.spec.containers[0].resources.limits.cpu}' -n "$QUESTION_ID")" = "250m" ]

check_criterion "Pod 'sized-app' limits memory=128Mi" \
  [ "$(kget pod sized-app '{.spec.containers[0].resources.limits.memory}' -n "$QUESTION_ID")" = "128Mi" ]

print_score
