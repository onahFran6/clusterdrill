#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e` - a failed criterion is a
# normal result, not a script error (see lib/grading.sh header).
set -uo pipefail

QUESTION_ID="q107-19-describe-find-image-pull-error${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'catalog-api' uses image nginx:1.25-alpine" \
  [ "$(kget pod catalog-api '{.spec.containers[0].image}' -n "$QUESTION_ID")" = "nginx:1.25-alpine" ]

check_criterion "Pod 'catalog-api' phase is Running" \
  [ "$(kget pod catalog-api '{.status.phase}' -n "$QUESTION_ID")" = "Running" ]

check_criterion "Pod 'catalog-api' container is ready" \
  [ "$(kget pod catalog-api '{.status.containerStatuses[0].ready}' -n "$QUESTION_ID")" = "true" ]

print_score
