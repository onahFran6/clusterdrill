#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q114-02-pending-access-mode${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "PVC amazon-pvc exists with accessModes=[ReadWriteOnce]" \
  bash -c '
    mode="$(kubectl get pvc amazon-pvc -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.accessModes[0]}" 2>/dev/null)"
    count="$(kubectl get pvc amazon-pvc -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.accessModes[*]}" 2>/dev/null | wc -w | tr -d " ")"
    [ "$mode" = "ReadWriteOnce" ] && [ "$count" = "1" ]
  '

check_criterion "PVC amazon-pvc is Bound to q114-02-pv" \
  bash -c '
    phase="$(kubectl get pvc amazon-pvc -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
    vol="$(kubectl get pvc amazon-pvc -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.volumeName}" 2>/dev/null)"
    [ "$phase" = "Bound" ] && [ "$vol" = "q114-02-pv" ]
  '

print_score
