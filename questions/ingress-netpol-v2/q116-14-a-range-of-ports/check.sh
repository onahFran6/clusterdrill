#!/usr/bin/env bash
# Spec-only checks: this bank's supported-cluster contract does not
# guarantee a NetworkPolicy-enforcing CNI, so only the object's own fields
# are asserted here, never live traffic blocking (and even on an
# enforcing CNI, a port-range check that stays "allowed" both before and
# after the fix proves nothing - see this topic's build notes).
set -uo pipefail

QUESTION_ID="q116-14-a-range-of-ports${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "NetworkPolicy 'game-ports' exists, podSelector matches app=game, policyTypes=['Ingress']" \
  bash -c "kubectl get networkpolicy game-ports -n '$QUESTION_ID' >/dev/null 2>&1 && \
    [ \"\$(kubectl get networkpolicy game-ports -n '$QUESTION_ID' -o jsonpath='{.spec.podSelector.matchLabels.app}')\" = 'game' ] && \
    [ \"\$(kubectl get networkpolicy game-ports -n '$QUESTION_ID' -o jsonpath='{.spec.policyTypes}')\" = '[\"Ingress\"]' ]"

check_criterion "Exactly one ports entry: TCP 7000-7100 (endPort), from role=player only" \
  bash -c "kubectl get networkpolicy game-ports -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e '(.spec.ingress | length) == 1 and \
      (.spec.ingress[0].ports == [{\"protocol\":\"TCP\",\"port\":7000,\"endPort\":7100}]) and \
      (.spec.ingress[0].from == [{\"podSelector\":{\"matchLabels\":{\"role\":\"player\"}}}])' >/dev/null"

print_score
