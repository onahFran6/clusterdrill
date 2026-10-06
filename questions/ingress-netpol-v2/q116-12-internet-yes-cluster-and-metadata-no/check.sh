#!/usr/bin/env bash
# Spec-only checks: this bank's supported-cluster contract does not
# guarantee a NetworkPolicy-enforcing CNI, so only the object's own fields
# are asserted here, never live traffic blocking.
set -uo pipefail

QUESTION_ID="q116-12-internet-yes-cluster-and-metadata-no${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "NetworkPolicy 'fetcher-egress' exists, podSelector matches app=fetcher, policyTypes=['Egress']" \
  bash -c "kubectl get networkpolicy fetcher-egress -n '$QUESTION_ID' >/dev/null 2>&1 && \
    [ \"\$(kubectl get networkpolicy fetcher-egress -n '$QUESTION_ID' -o jsonpath='{.spec.podSelector.matchLabels.app}')\" = 'fetcher' ] && \
    [ \"\$(kubectl get networkpolicy fetcher-egress -n '$QUESTION_ID' -o jsonpath='{.spec.policyTypes}')\" = '[\"Egress\"]' ]"

check_criterion "One egress rule is an ipBlock 0.0.0.0/0 excepting exactly the 4 required ranges" \
  bash -c "kubectl get networkpolicy fetcher-egress -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e '[.spec.egress[]?.to[]? | select(.ipBlock.cidr == \"0.0.0.0/0\") | .ipBlock.except | sort] | any(. == [\"10.0.0.0/8\", \"169.254.169.254/32\", \"172.16.0.0/12\", \"192.168.0.0/16\"])' >/dev/null"

check_criterion "A second egress rule allows the real CoreDNS selectors on 53/UDP+TCP" \
  bash -c "kubectl get networkpolicy fetcher-egress -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e '[.spec.egress[]? | select(
      ([.to[]? | select(.namespaceSelector.matchLabels.\"kubernetes.io/metadata.name\" == \"kube-system\" and .podSelector.matchLabels.\"k8s-app\" == \"kube-dns\")] | length == 1) and
      ((.ports // []) | sort) == ([{\"protocol\":\"UDP\",\"port\":53},{\"protocol\":\"TCP\",\"port\":53}] | sort)
    )] | length == 1' >/dev/null"

print_score
