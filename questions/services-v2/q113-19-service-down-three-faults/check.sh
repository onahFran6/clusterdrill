#!/usr/bin/env bash
# Mixed grading: plain Service routing (selector/targetPort/live traffic) is
# CNI-independent and graded live. The NetworkPolicy fault is spec-only,
# same rationale as every other NetworkPolicy question in this bank - this
# cluster's default CNI does not enforce NetworkPolicy, so even the
# unfixed policy would never actually block the live HTTP check below.
set -uo pipefail

QUESTION_ID="q113-19-service-down-three-faults${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Service 'orders-svc' selector is {app: orders}" \
  [ "$(kget service orders-svc '{.spec.selector.app}' -n "$QUESTION_ID")" = "orders" ]

check_criterion "Service 'orders-svc' targetPort is 80" \
  [ "$(kget service orders-svc '{.spec.ports[0].targetPort}' -n "$QUESTION_ID")" = "80" ]

check_criterion "functional: 'client' can reach orders-svc and gets the nginx page" \
  bash -c "
    for i in 1 2 3 4 5 6; do
      out=\$(kubectl exec client -n '$QUESTION_ID' -- wget -qO- -T 3 orders-svc 2>/dev/null)
      if echo \"\$out\" | grep -q '<title>'; then exit 0; fi
      sleep 2
    done
    exit 1
  "

check_criterion "NetworkPolicy 'allow-client' from-selector is fixed to {app: client}" \
  [ "$(kget networkpolicy allow-client '{.spec.ingress[0].from[0].podSelector.matchLabels.app}' -n "$QUESTION_ID")" = "client" ]

print_score
