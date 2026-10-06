#!/usr/bin/env bash
# Spec-only checks: this bank's supported-cluster contract does not
# guarantee a NetworkPolicy-enforcing CNI, so only the object's own fields
# are asserted here, never live traffic blocking.
set -uo pipefail

QUESTION_ID="q116-17-the-policy-that-protects-nothing${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
WRONG_NS="${QUESTION_ID}-wrong"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "No NetworkPolicy 'web-only-frontend' remains in the wrong namespace ($WRONG_NS)" \
  bash -c "! kubectl get networkpolicy web-only-frontend -n '$WRONG_NS' >/dev/null 2>&1"

check_criterion "NetworkPolicy 'web-only-frontend' exists in $QUESTION_ID, podSelector matches app=web (exact case)" \
  [ "$(kget networkpolicy web-only-frontend '{.spec.podSelector.matchLabels.app}' -n "$QUESTION_ID")" = "web" ]

check_criterion "Its ingress rule allows from app=frontend" \
  bash -c "kubectl get networkpolicy web-only-frontend -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e '[.spec.ingress[]?.from[]? | select(.podSelector.matchLabels.app == \"frontend\")] | length >= 1' >/dev/null"

print_score
