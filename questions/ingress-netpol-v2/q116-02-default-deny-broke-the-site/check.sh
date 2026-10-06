#!/usr/bin/env bash
# Spec-only checks: this bank's supported-cluster contract does not
# guarantee a NetworkPolicy-enforcing CNI, so only the object's own fields
# are asserted here, never live traffic blocking.
set -uo pipefail

QUESTION_ID="q116-02-default-deny-broke-the-site${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "NetworkPolicy 'allow-ingress-controller' exists in $QUESTION_ID" \
  resource_exists networkpolicy allow-ingress-controller -n "$QUESTION_ID"

check_criterion "podSelector matches app=site, policyTypes is exactly ['Ingress']" \
  bash -c "[ \"\$(kubectl get networkpolicy allow-ingress-controller -n '$QUESTION_ID' -o jsonpath='{.spec.podSelector.matchLabels.app}' 2>/dev/null)\" = 'site' ] && \
    [ \"\$(kubectl get networkpolicy allow-ingress-controller -n '$QUESTION_ID' -o jsonpath='{.spec.policyTypes}' 2>/dev/null)\" = '[\"Ingress\"]' ]"

check_criterion "Its one ingress rule allows from the real ingress-nginx controller selectors" \
  bash -c "kubectl get networkpolicy allow-ingress-controller -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e '[.spec.ingress[]?.from[]? | select(.namespaceSelector.matchLabels.\"kubernetes.io/metadata.name\" == \"ingress-nginx\" and .podSelector.matchLabels.\"app.kubernetes.io/name\" == \"ingress-nginx\")] | length >= 1' >/dev/null"

check_criterion "Its one ingress rule's ports is exactly [{TCP, 5678}] (the container port, not the Service port)" \
  bash -c "kubectl get networkpolicy allow-ingress-controller -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e '[.spec.ingress[]?.ports[]?] | length == 1 and .[0].protocol == \"TCP\" and .[0].port == 5678' >/dev/null"

# setup.sh already leaves default-deny in its correct, untouched shape, so
# grading that alone would be trivially true before the candidate does
# anything. Bundle it with allow-ingress-controller's own existence so this
# criterion only starts passing once the candidate has actually acted.
check_criterion "NetworkPolicy 'default-deny' still exists, unchanged AND 'allow-ingress-controller' exists" \
  bash -c "[ \"\$(kubectl get networkpolicy default-deny -n '$QUESTION_ID' -o jsonpath='{.spec.podSelector}' 2>/dev/null)\" = '{}' ] && \
    [ \"\$(kubectl get networkpolicy default-deny -n '$QUESTION_ID' -o jsonpath='{.spec.policyTypes}' 2>/dev/null)\" = '[\"Ingress\"]' ] && \
    kubectl get networkpolicy allow-ingress-controller -n '$QUESTION_ID' >/dev/null 2>&1"

print_score
