#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q109-10-access-mode-rwo-vs-rwx${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "PVC 'shared-claim' now requests ReadWriteOnce" \
  [ "$(kget pvc shared-claim '{.spec.accessModes[0]}' -n "$QUESTION_ID")" = "ReadWriteOnce" ]

check_criterion "PVC 'shared-claim' is Bound" \
  [ "$(kget pvc shared-claim '{.status.phase}' -n "$QUESTION_ID")" = "Bound" ]

check_criterion "PVC 'shared-claim' is bound to q109-10-shared-pv" \
  [ "$(kget pvc shared-claim '{.spec.volumeName}' -n "$QUESTION_ID")" = "q109-10-shared-pv" ]

print_score
