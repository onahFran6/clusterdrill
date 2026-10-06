#!/usr/bin/env bash
# Every one of these four faults is a pure object-state fact, fully
# gradable without any working Ingress controller or NetworkPolicy-
# enforcing CNI - same spec-only rationale as every other question in this
# topic, just applied across four independent faults in one chain.
set -uo pipefail

QUESTION_ID="q116-20-end-to-end-four-faults-one-request${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
DATA_NS="${QUESTION_ID}-data"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Fault 1 fixed: Ingress 'carina' backend port is now 80 (web-svc's real port)" \
  bash -c "kubectl get ingress carina -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e '.spec.rules[0].http.paths[0].backend.service.name == \"web-svc\" and .spec.rules[0].http.paths[0].backend.service.port.number == 80' >/dev/null"

check_criterion "Fault 2 fixed: some NetworkPolicy in this namespace allows the real ingress-nginx controller on port 8080, for 'web' pods" \
  bash -c "kubectl get networkpolicy -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e '[.items[] | select(
      (.spec.podSelector == {} or .spec.podSelector.matchLabels.app == \"web\") and
      ((.spec.ingress // []) | any(.[];
        (.ports // []) == [{\"protocol\":\"TCP\",\"port\":8080}] and
        ([.from[]? | select(.namespaceSelector.matchLabels.\"kubernetes.io/metadata.name\" == \"ingress-nginx\" and .podSelector.matchLabels.\"app.kubernetes.io/name\" == \"ingress-nginx\")] | length == 1)
      ))
    )] | length >= 1' >/dev/null"

check_criterion "Fault 3 fixed: some NetworkPolicy in this namespace grants DNS egress (real CoreDNS selectors, 53/UDP+TCP) for 'web' pods" \
  bash -c "kubectl get networkpolicy -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e '[.items[] | select(
      (.spec.podSelector == {} or .spec.podSelector.matchLabels.app == \"web\") and
      ((.spec.egress // []) | any(.[];
        ([.to[]? | select(.namespaceSelector.matchLabels.\"kubernetes.io/metadata.name\" == \"kube-system\" and .podSelector.matchLabels.\"k8s-app\" == \"kube-dns\")] | length == 1) and
        ((.ports // []) | sort) == ([{\"protocol\":\"UDP\",\"port\":53},{\"protocol\":\"TCP\",\"port\":53}] | sort)
      ))
    )] | length >= 1' >/dev/null"

# setup.sh already leaves quotes-from-carina in its correct, untouched
# shape, so grading that alone would be trivially true before the
# candidate does anything. Bundle it with fault 4's own fix (the two are
# directly related - the label is what that unedited policy expects) so
# this criterion only starts passing once the candidate has actually
# acted.
check_criterion "Fault 4 fixed: this namespace carries label team=carina AND the other team's 'quotes-from-carina' is still unchanged" \
  bash -c "[ \"\$(kubectl get namespace '$QUESTION_ID' -o jsonpath='{.metadata.labels.team}' 2>/dev/null)\" = 'carina' ] && \
    kubectl get networkpolicy quotes-from-carina -n '$DATA_NS' -o json 2>/dev/null | \
    jq -e '.spec.podSelector.matchLabels.app == \"quotes\" and .spec.policyTypes == [\"Ingress\"] and \
      ([.spec.ingress[]?.from[]? | select(.namespaceSelector.matchLabels.team == \"carina\")] | length == 1)' >/dev/null"

print_score
