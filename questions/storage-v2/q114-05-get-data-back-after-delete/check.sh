#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q114-05-get-data-back-after-delete${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "PVC rhine-new is Bound to q114-05-pv" \
  bash -c '
    phase="$(kubectl get pvc rhine-new -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
    vol="$(kubectl get pvc rhine-new -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.volumeName}" 2>/dev/null)"
    [ "$phase" = "Bound" ] && [ "$vol" = "q114-05-pv" ]
  '

check_criterion "Pod reader is Running" \
  bash -c '[ "$(kubectl get pod reader -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)" = "Running" ]'

check_criterion "reader's logs contain the data writer saved (Retain preserved it through delete)" \
  bash -c 'kubectl logs reader -n "'"$QUESTION_ID"'" 2>/dev/null | grep -q "precious data"'

print_score
