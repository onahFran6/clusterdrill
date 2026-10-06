#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q114-03-which-size-wins${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "PVC danube-claim requests 2Gi on manual-q114-03" \
  bash -c '
    req="$(kubectl get pvc danube-claim -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.resources.requests.storage}" 2>/dev/null)"
    sc="$(kubectl get pvc danube-claim -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.storageClassName}" 2>/dev/null)"
    [ "$req" = "2Gi" ] && [ "$sc" = "manual-q114-03" ]
  '

check_criterion "danube-claim is Bound to q114-03-5g (smallest PV that fits) with 5Gi reported capacity" \
  bash -c '
    phase="$(kubectl get pvc danube-claim -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
    vol="$(kubectl get pvc danube-claim -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.volumeName}" 2>/dev/null)"
    cap="$(kubectl get pvc danube-claim -n "'"$QUESTION_ID"'" -o jsonpath="{.status.capacity.storage}" 2>/dev/null)"
    [ "$phase" = "Bound" ] && [ "$vol" = "q114-03-5g" ] && [ "$cap" = "5Gi" ]
  '

print_score
