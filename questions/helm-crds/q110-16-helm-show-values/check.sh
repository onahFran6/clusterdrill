#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q110-16-helm-show-values${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "ConfigMap 'chart-defaults' exists in $QUESTION_ID" \
  resource_exists configmap chart-defaults -n "$QUESTION_ID"

check_criterion "ConfigMap 'chart-defaults' has data.region=us-east-1" \
  [ "$(kget configmap chart-defaults '{.data.region}' -n "$QUESTION_ID")" = "us-east-1" ]

print_score
