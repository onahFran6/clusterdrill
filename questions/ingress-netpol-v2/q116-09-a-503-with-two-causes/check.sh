#!/usr/bin/env bash
# Mostly spec-only (Ingress placement/routing), same rationale as every
# other Ingress question in this bank - but the Service selector and its
# resulting endpoints are core API-server state, independent of any
# controller/CNI, so that part is graded as a real, live functional check
# (see this topic's build notes on this distinction).
set -uo pipefail

QUESTION_ID="q116-09-a-503-with-two-causes${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
WRONG_NS="${QUESTION_ID}-wrong"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "No Ingress 'eclipse' remains in the wrong namespace ($WRONG_NS)" \
  bash -c "! kubectl get ingress eclipse -n '$WRONG_NS' >/dev/null 2>&1"

check_criterion "Ingress 'eclipse' exists in $QUESTION_ID, host eclipse.local, routing / to web-svc:80" \
  bash -c "kubectl get ingress eclipse -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e '.spec.rules[0].host == \"eclipse.local\" and \
      ([.spec.rules[0].http.paths[]? | select(.path == \"/\" and .backend.service.name == \"web-svc\" and .backend.service.port.number == 80)] | length == 1)' >/dev/null"

check_criterion "Service 'web-svc' selector now matches the real pod labels (app=web)" \
  [ "$(kget service web-svc '{.spec.selector.app}' -n "$QUESTION_ID")" = "web" ]

# Async: EndpointSlice population can lag a selector fix by a second or
# two, so retry briefly rather than taking one snapshot.
ENDPOINTS_OK="no"
for _ in 1 2 3 4 5 6; do
  count="$(kubectl get endpointslices -n "$QUESTION_ID" -l kubernetes.io/service-name=web-svc \
    -o jsonpath='{range .items[*]}{.endpoints[*].addresses[*]}{"\n"}{end}' 2>/dev/null | grep -c '[^[:space:]]')"
  if [ "${count:-0}" -ge 1 ]; then
    ENDPOINTS_OK="yes"
    break
  fi
  sleep 1
done
check_criterion "Service 'web-svc' now has at least one live endpoint" \
  [ "$ENDPOINTS_OK" = "yes" ]

print_score
