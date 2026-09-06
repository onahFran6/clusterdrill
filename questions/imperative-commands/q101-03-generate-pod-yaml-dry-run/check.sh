#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q101-03-generate-pod-yaml-dry-run${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'yaml-seed' exists in $QUESTION_ID" \
  resource_exists pod yaml-seed -n "$QUESTION_ID"

check_criterion "Pod 'yaml-seed' runs image 'redis:7-alpine'" \
  [ "$(kget pod yaml-seed '{.spec.containers[0].image}' -n "$QUESTION_ID")" = "redis:7-alpine" ]

print_score
