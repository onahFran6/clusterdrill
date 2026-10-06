#!/usr/bin/env bash
# Spec-only checks: this bank's supported-cluster contract does not
# guarantee a NetworkPolicy-enforcing CNI, so only the object's own fields
# are asserted here, never live traffic blocking.
set -uo pipefail

QUESTION_ID="q116-16-selecting-with-expressions${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "NetworkPolicy 'ledger-callers' exists, podSelector matches app=ledger, policyTypes=['Ingress']" \
  bash -c "kubectl get networkpolicy ledger-callers -n '$QUESTION_ID' >/dev/null 2>&1 && \
    [ \"\$(kubectl get networkpolicy ledger-callers -n '$QUESTION_ID' -o jsonpath='{.spec.podSelector.matchLabels.app}')\" = 'ledger' ] && \
    [ \"\$(kubectl get networkpolicy ledger-callers -n '$QUESTION_ID' -o jsonpath='{.spec.policyTypes}')\" = '[\"Ingress\"]' ]"

# Set-compared via jq (values and expression order both don't matter):
# team In [payments, billing]; env NotIn [dev]; audited Exists.
check_criterion "Its one ingress[0].from[0].podSelector.matchExpressions is exactly the 3 required expressions" \
  bash -c "kubectl get networkpolicy ledger-callers -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e '[.spec.ingress[0].from[0].podSelector.matchExpressions[]? | {key, operator, values: ((.values // []) | sort)}] | sort_by(.key) == [
      {\"key\":\"audited\",\"operator\":\"Exists\",\"values\":[]},
      {\"key\":\"env\",\"operator\":\"NotIn\",\"values\":[\"dev\"]},
      {\"key\":\"team\",\"operator\":\"In\",\"values\":[\"billing\",\"payments\"]}
    ]' >/dev/null"

print_score
