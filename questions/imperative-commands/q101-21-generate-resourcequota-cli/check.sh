#!/usr/bin/env bash
# Grades ONLY live cluster state.
# No `set -e` on purpose - see lib/grading.sh header comment.
set -uo pipefail

QUESTION_ID="q101-21-generate-resourcequota-cli${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "ResourceQuota 'build-cap' exists in $QUESTION_ID" \
  resource_exists resourcequota build-cap -n "$QUESTION_ID"

check_criterion "ResourceQuota 'build-cap' caps cpu at 2" \
  [ "$(kget resourcequota build-cap '{.spec.hard.cpu}' -n "$QUESTION_ID")" = "2" ]

check_criterion "ResourceQuota 'build-cap' caps memory at 2Gi" \
  [ "$(kget resourcequota build-cap '{.spec.hard.memory}' -n "$QUESTION_ID")" = "2Gi" ]

check_criterion "ResourceQuota 'build-cap' caps pods at 3" \
  [ "$(kget resourcequota build-cap '{.spec.hard.pods}' -n "$QUESTION_ID")" = "3" ]

print_score
