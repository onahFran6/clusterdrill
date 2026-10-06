#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q114-04-reserve-for-a-future-claim${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "q114-04-a's claimRef points at $QUESTION_ID/reserved" \
  bash -c '
    ns="$(kubectl get pv q114-04-a -o jsonpath="{.spec.claimRef.namespace}" 2>/dev/null)"
    name="$(kubectl get pv q114-04-a -o jsonpath="{.spec.claimRef.name}" 2>/dev/null)"
    [ "$ns" = "'"$QUESTION_ID"'" ] && [ "$name" = "reserved" ]
  '

check_criterion "PVC volga-claim is Bound to q114-04-b" \
  bash -c '
    phase="$(kubectl get pvc volga-claim -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
    vol="$(kubectl get pvc volga-claim -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.volumeName}" 2>/dev/null)"
    [ "$phase" = "Bound" ] && [ "$vol" = "q114-04-b" ]
  '

check_criterion "PVC other exists and stays Pending (no free PV, no provisioner)" \
  bash -c '
    kubectl get pvc other -n "'"$QUESTION_ID"'" >/dev/null 2>&1 || exit 1
    phase="$(kubectl get pvc other -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
    [ "$phase" = "Pending" ]
  '

check_criterion "PVC reserved is Bound to q114-04-a" \
  bash -c '
    phase="$(kubectl get pvc reserved -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
    vol="$(kubectl get pvc reserved -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.volumeName}" 2>/dev/null)"
    [ "$phase" = "Bound" ] && [ "$vol" = "q114-04-a" ]
  '

print_score
