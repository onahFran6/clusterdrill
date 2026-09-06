#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q109-11-pvc-resize-allow-expansion${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "PVC 'growing-claim' now requests 2Gi" \
  [ "$(kget pvc growing-claim '{.spec.resources.requests.storage}' -n "$QUESTION_ID")" = "2Gi" ]

print_score
