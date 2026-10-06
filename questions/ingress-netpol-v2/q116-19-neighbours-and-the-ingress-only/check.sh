#!/usr/bin/env bash
# Spec-only checks: this bank's supported-cluster contract does not
# guarantee a NetworkPolicy-enforcing CNI, so only the object's own fields
# are asserted here, never live traffic blocking.
set -uo pipefail

QUESTION_ID="q116-19-neighbours-and-the-ingress-only${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "NetworkPolicy 'shop-sources' exists, podSelector matches app=shop, policyTypes=['Ingress']" \
  bash -c "kubectl get networkpolicy shop-sources -n '$QUESTION_ID' >/dev/null 2>&1 && \
    [ \"\$(kubectl get networkpolicy shop-sources -n '$QUESTION_ID' -o jsonpath='{.spec.podSelector.matchLabels.app}')\" = 'shop' ] && \
    [ \"\$(kubectl get networkpolicy shop-sources -n '$QUESTION_ID' -o jsonpath='{.spec.policyTypes}')\" = '[\"Ingress\"]' ]"

check_criterion "Its one ingress[0].from has exactly 2 entries: bare podSelector:{} AND the real ingress-nginx selectors" \
  bash -c "kubectl get networkpolicy shop-sources -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e '(.spec.ingress | length) == 1 and (.spec.ingress[0].from | length) == 2 and \
      ([.spec.ingress[0].from[] | select(. == {\"podSelector\":{}})] | length == 1) and \
      ([.spec.ingress[0].from[] | select(.namespaceSelector.matchLabels.\"kubernetes.io/metadata.name\" == \"ingress-nginx\" and .podSelector.matchLabels.\"app.kubernetes.io/name\" == \"ingress-nginx\")] | length == 1)' >/dev/null"

print_score
