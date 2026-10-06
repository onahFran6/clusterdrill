#!/usr/bin/env bash
# Spec-only checks: this bank's supported-cluster contract does not
# guarantee a working ingress-nginx controller, so only live object state
# is asserted here, never a live HTTP response.
set -uo pipefail

QUESTION_ID="q116-06-route-by-port-name${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Service 'app-svc' port is named 'web' (number still 80)" \
  bash -c "kubectl get service app-svc -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e '.spec.ports[0].name == \"web\" and .spec.ports[0].port == 80' >/dev/null"

check_criterion "Ingress 'cosmos' exists in $QUESTION_ID" \
  resource_exists ingress cosmos -n "$QUESTION_ID"

check_criterion "Path '/healthz' is pathType Exact routed to health-svc:80 (by number)" \
  bash -c "kubectl get ingress cosmos -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e '[.spec.rules[0].http.paths[]? | select(.path == \"/healthz\" and .pathType == \"Exact\" and .backend.service.name == \"health-svc\" and .backend.service.port.number == 80)] | length == 1' >/dev/null"

check_criterion "Path '/' is pathType Prefix routed to app-svc by port NAME 'web' (not a number)" \
  bash -c "kubectl get ingress cosmos -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e '[.spec.rules[0].http.paths[]? | select(.path == \"/\" and .pathType == \"Prefix\" and .backend.service.name == \"app-svc\" and .backend.service.port.name == \"web\")] | length == 1' >/dev/null"

print_score
