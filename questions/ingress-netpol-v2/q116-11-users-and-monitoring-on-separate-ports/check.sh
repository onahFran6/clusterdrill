#!/usr/bin/env bash
# Spec-only checks: this bank's supported-cluster contract does not
# guarantee a NetworkPolicy-enforcing CNI, so only the object's own fields
# are asserted here, never live traffic blocking.
set -uo pipefail

QUESTION_ID="q116-11-users-and-monitoring-on-separate-ports${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
MONITORING_NS="${QUESTION_ID}-monitoring"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "NetworkPolicy 'api-access' exists, podSelector matches app=api, policyTypes=['Ingress']" \
  bash -c "kubectl get networkpolicy api-access -n '$QUESTION_ID' >/dev/null 2>&1 && \
    [ \"\$(kubectl get networkpolicy api-access -n '$QUESTION_ID' -o jsonpath='{.spec.podSelector.matchLabels.app}')\" = 'api' ] && \
    [ \"\$(kubectl get networkpolicy api-access -n '$QUESTION_ID' -o jsonpath='{.spec.policyTypes}')\" = '[\"Ingress\"]' ]"

check_criterion "Exactly 2 ingress rule items" \
  bash -c "kubectl get networkpolicy api-access -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e '(.spec.ingress | length) == 2' >/dev/null"

check_criterion "One item allows the real ingress-nginx controller selectors on port 'http'" \
  bash -c "kubectl get networkpolicy api-access -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e '[.spec.ingress[]? | select(
      (.ports // []) == [{\"protocol\":\"TCP\",\"port\":\"http\"}] and
      ([.from[]? | select(.namespaceSelector.matchLabels.\"kubernetes.io/metadata.name\" == \"ingress-nginx\" and .podSelector.matchLabels.\"app.kubernetes.io/name\" == \"ingress-nginx\")] | length == 1)
    )] | length == 1' >/dev/null"

check_criterion "One item allows any pod in the real monitoring namespace ($MONITORING_NS) on port 'metrics'" \
  bash -c "kubectl get networkpolicy api-access -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e --arg ns \"$MONITORING_NS\" '[.spec.ingress[]? | select(
      (.ports // []) == [{\"protocol\":\"TCP\",\"port\":\"metrics\"}] and
      ([.from[]? | select(.namespaceSelector.matchLabels.\"kubernetes.io/metadata.name\" == \$ns)] | length == 1)
    )] | length == 1' >/dev/null"

print_score
