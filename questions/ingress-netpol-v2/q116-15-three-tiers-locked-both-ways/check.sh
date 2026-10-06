#!/usr/bin/env bash
# Spec-only checks: this bank's supported-cluster contract does not
# guarantee a NetworkPolicy-enforcing CNI, so only each object's own fields
# are asserted here, never live traffic blocking.
set -uo pipefail

QUESTION_ID="q116-15-three-tiers-locked-both-ways${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "NetworkPolicy 'web': ingress from the real ingress-nginx selectors on port 8080" \
  bash -c "kubectl get networkpolicy web -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e '.spec.podSelector.matchLabels.tier == \"web\" and \
      ([.spec.ingress[]? | select(
        (.ports // []) == [{\"protocol\":\"TCP\",\"port\":8080}] and
        ([.from[]? | select(.namespaceSelector.matchLabels.\"kubernetes.io/metadata.name\" == \"ingress-nginx\" and .podSelector.matchLabels.\"app.kubernetes.io/name\" == \"ingress-nginx\")] | length == 1)
      )] | length == 1)' >/dev/null"

check_criterion "NetworkPolicy 'web': egress to tier=api on port 8080" \
  bash -c "kubectl get networkpolicy web -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e '[.spec.egress[]? | select(
      (.ports // []) == [{\"protocol\":\"TCP\",\"port\":8080}] and
      ([.to[]? | select(.podSelector.matchLabels.tier == \"api\")] | length == 1)
    )] | length == 1' >/dev/null"

check_criterion "NetworkPolicy 'api': ingress from tier=web on port 8080" \
  bash -c "kubectl get networkpolicy api -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e '.spec.podSelector.matchLabels.tier == \"api\" and \
      ([.spec.ingress[]? | select(
        (.ports // []) == [{\"protocol\":\"TCP\",\"port\":8080}] and
        ([.from[]? | select(.podSelector.matchLabels.tier == \"web\")] | length == 1)
      )] | length == 1)' >/dev/null"

check_criterion "NetworkPolicy 'api': egress to tier=db on TCP 5432" \
  bash -c "kubectl get networkpolicy api -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e '[.spec.egress[]? | select(
      (.ports // []) == [{\"protocol\":\"TCP\",\"port\":5432}] and
      ([.to[]? | select(.podSelector.matchLabels.tier == \"db\")] | length == 1)
    )] | length == 1' >/dev/null"

check_criterion "NetworkPolicy 'db': ingress from tier=api on TCP 5432 only, no egress rule of its own" \
  bash -c "kubectl get networkpolicy db -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e '.spec.podSelector.matchLabels.tier == \"db\" and \
      .spec.policyTypes == [\"Ingress\"] and \
      ([.spec.ingress[]? | select(
        (.ports // []) == [{\"protocol\":\"TCP\",\"port\":5432}] and
        ([.from[]? | select(.podSelector.matchLabels.tier == \"api\")] | length == 1)
      )] | length == 1)' >/dev/null"

# setup.sh already leaves deny-all/allow-dns in their correct, untouched
# shape, so grading that alone would be trivially true before the
# candidate does anything. Bundle it with all three new tier policies
# existing so this criterion only starts passing once the candidate has
# actually built the chain.
check_criterion "'deny-all'/'allow-dns' unchanged AND all three tier policies ('web','api','db') exist" \
  bash -c "[ \"\$(kubectl get networkpolicy deny-all -n '$QUESTION_ID' -o jsonpath='{.spec.podSelector}')\" = '{}' ] && \
    [ \"\$(kubectl get networkpolicy deny-all -n '$QUESTION_ID' -o jsonpath='{.spec.policyTypes}')\" = '[\"Ingress\",\"Egress\"]' ] && \
    [ \"\$(kubectl get networkpolicy allow-dns -n '$QUESTION_ID' -o jsonpath='{.spec.policyTypes}')\" = '[\"Egress\"]' ] && \
    kubectl get networkpolicy web -n '$QUESTION_ID' >/dev/null 2>&1 && \
    kubectl get networkpolicy api -n '$QUESTION_ID' >/dev/null 2>&1 && \
    kubectl get networkpolicy db -n '$QUESTION_ID' >/dev/null 2>&1"

print_score
