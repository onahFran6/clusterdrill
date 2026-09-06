#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q104-26-poddisruptionbudget-minavailable${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "PodDisruptionBudget 'checkout-svc-pdb' exists" \
  resource_exists poddisruptionbudget checkout-svc-pdb -n "$QUESTION_ID"

check_criterion "PDB 'checkout-svc-pdb' has minAvailable=2 and selects app=checkout-svc" \
  bash -c '
    min="$(kubectl get pdb checkout-svc-pdb -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.minAvailable}" 2>/dev/null)"
    [ "$min" = "2" ] || exit 1
    sel="$(kubectl get pdb checkout-svc-pdb -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.selector.matchLabels.app}" 2>/dev/null)"
    [ "$sel" = "checkout-svc" ]
  '

check_criterion "PDB 'checkout-svc-pdb' status reports 3 expected pods (correctly bound to the Deployment's 3 replicas)" \
  bash -c '
    expected="$(kubectl get pdb checkout-svc-pdb -n "'"$QUESTION_ID"'" -o jsonpath="{.status.expectedPods}" 2>/dev/null)"
    [ "$expected" = "3" ]
  '

print_score
