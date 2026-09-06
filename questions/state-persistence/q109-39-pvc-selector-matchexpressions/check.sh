#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q109-39-pvc-selector-matchexpressions${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "PVC 'gold-claim' selector uses matchExpressions: tier In [gold]" \
  bash -c "[ \"\$(kubectl get pvc gold-claim -n '$QUESTION_ID' -o jsonpath='{.spec.selector.matchExpressions[0].key}')\" = 'tier' ] && \
    [ \"\$(kubectl get pvc gold-claim -n '$QUESTION_ID' -o jsonpath='{.spec.selector.matchExpressions[0].operator}')\" = 'In' ] && \
    [ \"\$(kubectl get pvc gold-claim -n '$QUESTION_ID' -o jsonpath='{.spec.selector.matchExpressions[0].values[0]}')\" = 'gold' ]"

check_criterion "PVC 'gold-claim' is Bound to tier-gold-pv (not tier-bronze-pv)" \
  bash -c '
    for _ in $(seq 1 15); do
      vol="$(kubectl get pvc gold-claim -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.volumeName}" 2>/dev/null)"
      [ "$vol" = "tier-gold-pv" ] && exit 0
      sleep 2
    done
    exit 1
  '

print_score
