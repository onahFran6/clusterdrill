#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q109-22-pvc-pending-troubleshoot-mismatch${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "PVC 'fix-me-claim' is Bound" \
  [ "$(kget pvc fix-me-claim '{.status.phase}' -n "$QUESTION_ID")" = "Bound" ]

pv_capacity="$(kget pv fix-me-pv '{.spec.capacity.storage}')"
check_criterion "PV 'fix-me-pv' capacity is at least 200Mi" \
  bash -c '[[ "$1" =~ ^([0-9]+)Mi$ ]] && (( BASH_REMATCH[1] >= 200 ))' _ "$pv_capacity"

check_criterion "PVC 'fix-me-claim' is bound to fix-me-pv" \
  [ "$(kget pvc fix-me-claim '{.spec.volumeName}' -n "$QUESTION_ID")" = "fix-me-pv" ]

print_score
