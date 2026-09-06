#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q110-12-crd-jsonpath-field${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "ConfigMap 'inspected-playlist' exists in $QUESTION_ID" \
  resource_exists configmap inspected-playlist -n "$QUESTION_ID"

# 'focus' (trackCount 47) is the seeded maximum - the one correct answer.
check_criterion "ConfigMap 'inspected-playlist' names the correct winner (focus)" \
  [ "$(kget configmap inspected-playlist '{.data.winner}' -n "$QUESTION_ID")" = "focus" ]

print_score
