#!/usr/bin/env bash
# Spec-only checks: this bank's supported-cluster contract does not
# guarantee a NetworkPolicy-enforcing CNI, so only each object's own fields
# are asserted here, never live traffic blocking.
set -uo pipefail

QUESTION_ID="q116-13-lock-the-namespace-keep-it-working-inside${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "'deny-all' exists: empty podSelector, policyTypes [Ingress, Egress], no rules" \
  bash -c "kubectl get networkpolicy deny-all -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e '.spec.podSelector == {} and (.spec.policyTypes | sort) == [\"Egress\",\"Ingress\"] and (.spec.ingress // []) == [] and (.spec.egress // []) == []' >/dev/null"

check_criterion "'allow-dns' exists: policyTypes [Egress], one rule allowing real CoreDNS selectors on 53/UDP+TCP" \
  bash -c "kubectl get networkpolicy allow-dns -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e '.spec.policyTypes == [\"Egress\"] and \
      ([.spec.egress[]? | select(
        ([.to[]? | select(.namespaceSelector.matchLabels.\"kubernetes.io/metadata.name\" == \"kube-system\" and .podSelector.matchLabels.\"k8s-app\" == \"kube-dns\")] | length == 1) and
        ((.ports // []) | sort) == ([{\"protocol\":\"UDP\",\"port\":53},{\"protocol\":\"TCP\",\"port\":53}] | sort)
      )] | length == 1)' >/dev/null"

check_criterion "'allow-same-ns' exists: policyTypes [Ingress, Egress], bare podSelector:{} on both sides" \
  bash -c "kubectl get networkpolicy allow-same-ns -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e '(.spec.policyTypes | sort) == [\"Egress\",\"Ingress\"] and \
      ([.spec.ingress[]?.from[]? | select(. == {\"podSelector\":{}})] | length >= 1) and \
      ([.spec.egress[]?.to[]? | select(. == {\"podSelector\":{}})] | length >= 1)' >/dev/null"

print_score
