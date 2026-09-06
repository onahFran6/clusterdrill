#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q110-06-helm-get-values${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "ConfigMap 'inspected-values' exists in $QUESTION_ID" \
  resource_exists configmap inspected-values -n "$QUESTION_ID"

check_criterion "ConfigMap 'inspected-values' records the correct maxMemoryMb (256)" \
  [ "$(kget configmap inspected-values '{.data.maxMemoryMb}' -n "$QUESTION_ID")" = "256" ]

print_score
