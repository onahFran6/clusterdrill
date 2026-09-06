#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q110-08-crd-create-instance${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Widget 'gizmo' exists in $QUESTION_ID" \
  resource_exists widget gizmo -n "$QUESTION_ID"

check_criterion "Widget 'gizmo' has spec.color=blue" \
  [ "$(kget widget gizmo '{.spec.color}' -n "$QUESTION_ID")" = "blue" ]

check_criterion "Widget 'gizmo' has spec.weightGrams=150" \
  [ "$(kget widget gizmo '{.spec.weightGrams}' -n "$QUESTION_ID")" = "150" ]

print_score
