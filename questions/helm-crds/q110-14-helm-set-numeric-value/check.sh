#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q110-14-helm-set-numeric-value${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

HELM_STATUS="$(helm status grid -n "$QUESTION_ID" -o json 2>/dev/null | grep -o '"status":"[a-z-]*"' | head -1)"
check_criterion "Release 'grid' exists with status deployed" \
  [ "$HELM_STATUS" = '"status":"deployed"' ]

check_criterion "Deployment 'grid-scaler' exists in $QUESTION_ID" \
  resource_exists deployment grid-scaler -n "$QUESTION_ID"

check_criterion "Deployment 'grid-scaler' has 4 replicas requested" \
  [ "$(kget deployment grid-scaler '{.spec.replicas}' -n "$QUESTION_ID")" = "4" ]

check_criterion "Deployment 'grid-scaler' has 4 available replicas" \
  [ "$(kget deployment grid-scaler '{.status.availableReplicas}' -n "$QUESTION_ID")" = "4" ]

print_score
