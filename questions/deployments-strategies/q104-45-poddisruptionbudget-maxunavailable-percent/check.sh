#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q104-45-poddisruptionbudget-maxunavailable-percent${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "PodDisruptionBudget 'catalog-svc-pdb' exists" \
  resource_exists poddisruptionbudget catalog-svc-pdb -n "$QUESTION_ID"

check_criterion "PDB 'catalog-svc-pdb' has maxUnavailable=\"40%\" and selects app=catalog-svc" \
  bash -c '
    max="$(kubectl get pdb catalog-svc-pdb -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.maxUnavailable}" 2>/dev/null)"
    [ "$max" = "40%" ] || exit 1
    sel="$(kubectl get pdb catalog-svc-pdb -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.selector.matchLabels.app}" 2>/dev/null)"
    [ "$sel" = "catalog-svc" ]
  '

check_criterion "PDB 'catalog-svc-pdb' status reports 5 expected pods and allows 2 disruptions (40% of 5, rounded down)" \
  bash -c '
    expected="$(kubectl get pdb catalog-svc-pdb -n "'"$QUESTION_ID"'" -o jsonpath="{.status.expectedPods}" 2>/dev/null)"
    allowed="$(kubectl get pdb catalog-svc-pdb -n "'"$QUESTION_ID"'" -o jsonpath="{.status.disruptionsAllowed}" 2>/dev/null)"
    [ "$expected" = "5" ] && [ "$allowed" = "2" ]
  '

print_score
