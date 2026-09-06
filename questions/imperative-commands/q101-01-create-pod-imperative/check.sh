#!/usr/bin/env bash
# Grades ONLY live cluster state.
# No `set -e` on purpose - see lib/grading.sh header comment.
set -uo pipefail

QUESTION_ID="q101-01-create-pod-imperative${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'web-scratch' exists in $QUESTION_ID" \
  resource_exists pod web-scratch -n "$QUESTION_ID"

check_criterion "Pod 'web-scratch' runs image 'nginx:1.25-alpine'" \
  [ "$(kget pod web-scratch '{.spec.containers[0].image}' -n "$QUESTION_ID")" = "nginx:1.25-alpine" ]

check_criterion "Pod 'web-scratch' has exactly one container" \
  [ "$(kget pod web-scratch '{.spec.containers[*].name}' -n "$QUESTION_ID" | wc -w | tr -d ' ')" = "1" ]

print_score
