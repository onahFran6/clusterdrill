#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q109-20-pvc-bind-via-selector-empty-storageclass${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "PVC 'env-claim' exists in $QUESTION_ID" \
  resource_exists pvc env-claim -n "$QUESTION_ID"

check_criterion "PVC 'env-claim' requests storageClassName \"\"" \
  [ "$(kget pvc env-claim '{.metadata.name}' -n "$QUESTION_ID")" = "env-claim" -a \
    "$(kget pvc env-claim '{.spec.storageClassName}' -n "$QUESTION_ID")" = "" ]

check_criterion "PVC 'env-claim' requests ReadWriteOnce" \
  [ "$(kget pvc env-claim '{.spec.accessModes[0]}' -n "$QUESTION_ID")" = "ReadWriteOnce" ]

check_criterion "PVC 'env-claim' is Bound" \
  [ "$(kget pvc env-claim '{.status.phase}' -n "$QUESTION_ID")" = "Bound" ]

check_criterion "PVC 'env-claim' is bound to volume vol-green (not vol-blue)" \
  [ "$(kget pvc env-claim '{.spec.volumeName}' -n "$QUESTION_ID")" = "vol-green" ]

print_score
