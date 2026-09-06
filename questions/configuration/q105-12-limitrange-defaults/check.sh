#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-12-limitrange-defaults${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "LimitRange 'container-defaults' exists" \
  resource_exists limitrange container-defaults -n "$QUESTION_ID"

check_criterion "LimitRange default CPU limit is 200m" \
  [ "$(kget limitrange container-defaults '{.spec.limits[0].default.cpu}' -n "$QUESTION_ID")" = "200m" ]

check_criterion "LimitRange default memory limit is 256Mi" \
  [ "$(kget limitrange container-defaults '{.spec.limits[0].default.memory}' -n "$QUESTION_ID")" = "256Mi" ]

check_criterion "LimitRange default CPU request is 100m" \
  [ "$(kget limitrange container-defaults '{.spec.limits[0].defaultRequest.cpu}' -n "$QUESTION_ID")" = "100m" ]

check_criterion "LimitRange default memory request is 128Mi" \
  [ "$(kget limitrange container-defaults '{.spec.limits[0].defaultRequest.memory}' -n "$QUESTION_ID")" = "128Mi" ]

check_criterion "Pod 'plain-app' exists" \
  resource_exists pod plain-app -n "$QUESTION_ID"

check_criterion "Pod 'plain-app' actually received the default CPU limit (200m) from the LimitRange" \
  [ "$(kget pod plain-app '{.spec.containers[0].resources.limits.cpu}' -n "$QUESTION_ID")" = "200m" ]

check_criterion "Pod 'plain-app' actually received the default memory request (128Mi) from the LimitRange" \
  [ "$(kget pod plain-app '{.spec.containers[0].resources.requests.memory}' -n "$QUESTION_ID")" = "128Mi" ]

print_score
