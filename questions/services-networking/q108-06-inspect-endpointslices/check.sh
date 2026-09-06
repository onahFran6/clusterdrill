#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q108-06-inspect-endpointslices${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Compute the expected ready-address count once, from live EndpointSlice
# state, so the criterion below asserts against reality rather than a
# hardcoded number (replicas could in principle differ from what setup.sh
# seeded, if a future edit changes it).
expected_ready="$(kubectl get endpointslice -n "$QUESTION_ID" \
  -l kubernetes.io/service-name=order-api-svc \
  -o jsonpath='{range .items[*]}{range .endpoints[?(@.conditions.ready==true)]}{.addresses[*]}{"\n"}{end}{end}' 2>/dev/null \
  | grep -c .)"

check_criterion "ConfigMap 'order-api-endpoint-report' exists in $QUESTION_ID" \
  resource_exists configmap order-api-endpoint-report -n "$QUESTION_ID"

check_criterion "ConfigMap has non-empty 'ready-count' key" \
  [ -n "$(kget configmap order-api-endpoint-report '{.data.ready-count}' -n "$QUESTION_ID")" ]

check_criterion "ConfigMap 'ready-count' matches live EndpointSlice ready address count ($expected_ready)" \
  [ "$(kget configmap order-api-endpoint-report '{.data.ready-count}' -n "$QUESTION_ID")" = "$expected_ready" ]

print_score
