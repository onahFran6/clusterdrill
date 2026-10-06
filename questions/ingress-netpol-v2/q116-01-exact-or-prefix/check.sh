#!/usr/bin/env bash
# Spec-only checks: this bank's supported-cluster contract does not
# guarantee a working ingress-nginx controller, so only the Ingress
# object's own fields are asserted here, never a live HTTP response.
set -uo pipefail

QUESTION_ID="q116-01-exact-or-prefix${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Ingress 'meteor' exists in $QUESTION_ID" \
  resource_exists ingress meteor -n "$QUESTION_ID"

check_criterion "Ingress 'meteor' uses IngressClass nginx and host meteor.local" \
  bash -c "[ \"\$(kubectl get ingress meteor -n '$QUESTION_ID' -o jsonpath='{.spec.ingressClassName}' 2>/dev/null)\" = 'nginx' ] && \
    [ \"\$(kubectl get ingress meteor -n '$QUESTION_ID' -o jsonpath='{.spec.rules[0].host}' 2>/dev/null)\" = 'meteor.local' ]"

check_criterion "Ingress has exactly 2 path rules" \
  bash -c "kubectl get ingress meteor -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e '.spec.rules[0].http.paths | length == 2' >/dev/null"

check_criterion "Path '/docs' is pathType Exact routed to docs-svc:80" \
  bash -c "kubectl get ingress meteor -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e '[.spec.rules[0].http.paths[] | select(.path == \"/docs\" and .pathType == \"Exact\" and .backend.service.name == \"docs-svc\" and .backend.service.port.number == 80)] | length == 1' >/dev/null"

check_criterion "Path '/' is pathType Prefix routed to home-svc:80" \
  bash -c "kubectl get ingress meteor -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e '[.spec.rules[0].http.paths[] | select(.path == \"/\" and .pathType == \"Prefix\" and .backend.service.name == \"home-svc\" and .backend.service.port.number == 80)] | length == 1' >/dev/null"

print_score
