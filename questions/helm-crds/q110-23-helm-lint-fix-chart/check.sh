#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q110-23-helm-lint-fix-chart${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

CHART_DIR="$SCRIPT_DIR/chart"

RELEASE_STATUS="$(helm status fixed -n "$QUESTION_ID" -o json 2>/dev/null)"

check_criterion "Release 'fixed' exists in $QUESTION_ID" \
  [ -n "$RELEASE_STATUS" ]

RELEASE_STATE="$(echo "$RELEASE_STATUS" | grep -o '"status":"[^"]*"' | head -1)"
check_criterion "Release 'fixed' status is 'deployed'" \
  [ "$RELEASE_STATE" = '"status":"deployed"' ]

check_criterion "Deployment 'fixed-checkup' exists in $QUESTION_ID" \
  resource_exists deployment fixed-checkup -n "$QUESTION_ID"

IMAGE="$(kget deployment fixed-checkup '{.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")"
check_criterion "Deployment 'fixed-checkup' container image is exactly 'nginx:1.25-alpine'" \
  [ "$IMAGE" = "nginx:1.25-alpine" ]

CHART_VERSION="$(awk -F': *' '/^version:/{print $2}' "$CHART_DIR/Chart.yaml" 2>/dev/null | tr -d '"'"'"' \r')"
check_criterion "chart/Chart.yaml has a non-empty 'version:' field" \
  [ -n "$CHART_VERSION" ]

print_score
