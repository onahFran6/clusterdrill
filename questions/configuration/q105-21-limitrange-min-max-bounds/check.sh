#!/usr/bin/env bash
# Grades ONLY live cluster state.
# No `set -e` on purpose - see lib/grading.sh header comment.
set -uo pipefail

QUESTION_ID="q105-21-limitrange-min-max-bounds${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "LimitRange 'mem-bounds' exists in $QUESTION_ID" \
  resource_exists limitrange mem-bounds -n "$QUESTION_ID"

check_criterion "LimitRange 'mem-bounds' sets a Container memory min of 64Mi" \
  [ "$(kget limitrange mem-bounds '{.spec.limits[0].min.memory}' -n "$QUESTION_ID")" = "64Mi" ]

check_criterion "LimitRange 'mem-bounds' sets a Container memory max of 512Mi" \
  [ "$(kget limitrange mem-bounds '{.spec.limits[0].max.memory}' -n "$QUESTION_ID")" = "512Mi" ]

check_criterion "Pod 'bounded-app' exists in $QUESTION_ID" \
  resource_exists pod bounded-app -n "$QUESTION_ID"

check_criterion "Pod 'bounded-app' requests exactly 200Mi memory" \
  [ "$(kget pod bounded-app '{.spec.containers[0].resources.requests.memory}' -n "$QUESTION_ID")" = "200Mi" ]

print_score
