#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-11-resource-requests-limits${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'batch-worker' exists" \
  resource_exists pod batch-worker -n "$QUESTION_ID"

check_criterion "Container image is nginx:1.25-alpine" \
  [ "$(kget pod batch-worker '{.spec.containers[0].image}' -n "$QUESTION_ID")" = "nginx:1.25-alpine" ]

check_criterion "CPU request is 100m" \
  [ "$(kget pod batch-worker '{.spec.containers[0].resources.requests.cpu}' -n "$QUESTION_ID")" = "100m" ]

check_criterion "CPU limit is 250m" \
  [ "$(kget pod batch-worker '{.spec.containers[0].resources.limits.cpu}' -n "$QUESTION_ID")" = "250m" ]

check_criterion "Memory request is 128Mi" \
  [ "$(kget pod batch-worker '{.spec.containers[0].resources.requests.memory}' -n "$QUESTION_ID")" = "128Mi" ]

check_criterion "Memory limit is 256Mi" \
  [ "$(kget pod batch-worker '{.spec.containers[0].resources.limits.memory}' -n "$QUESTION_ID")" = "256Mi" ]

print_score
