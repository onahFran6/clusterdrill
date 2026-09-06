#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q109-12-pv-capacity-access-mode-mismatch${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "PVC 'oversized-claim' is Bound" \
  [ "$(kget pvc oversized-claim '{.status.phase}' -n "$QUESTION_ID")" = "Bound" ]

check_criterion "PVC 'oversized-claim' is bound to q109-12-small-pv" \
  [ "$(kget pvc oversized-claim '{.spec.volumeName}' -n "$QUESTION_ID")" = "q109-12-small-pv" ]

requested="$(kget pvc oversized-claim '{.spec.resources.requests.storage}' -n "$QUESTION_ID")"
check_criterion "PVC 'oversized-claim' requests at least 100Mi" \
  bash -c '[[ "$1" =~ ^([0-9]+)Mi$ ]] && (( BASH_REMATCH[1] >= 100 ))' _ "$requested"

print_score
