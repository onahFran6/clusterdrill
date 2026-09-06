#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q109-04-pvc-bind-static-pv${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "PVC 'data-claim' exists in $QUESTION_ID" \
  resource_exists pvc data-claim -n "$QUESTION_ID"

check_criterion "PVC 'data-claim' requests storageClassName manual-q109-04" \
  [ "$(kget pvc data-claim '{.spec.storageClassName}' -n "$QUESTION_ID")" = "manual-q109-04" ]

check_criterion "PVC 'data-claim' requests ReadWriteOnce" \
  [ "$(kget pvc data-claim '{.spec.accessModes[0]}' -n "$QUESTION_ID")" = "ReadWriteOnce" ]

check_criterion "PVC 'data-claim' is Bound" \
  [ "$(kget pvc data-claim '{.status.phase}' -n "$QUESTION_ID")" = "Bound" ]

check_criterion "PVC 'data-claim' is bound to volume q109-04-static-pv" \
  [ "$(kget pvc data-claim '{.spec.volumeName}' -n "$QUESTION_ID")" = "q109-04-static-pv" ]

print_score
