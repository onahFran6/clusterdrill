#!/usr/bin/env bash
# Spec-only checks: this bank's supported-cluster contract does not
# guarantee a working ingress-nginx controller, so only the Ingress
# object's own fields are asserted here, never a live HTTP response.
set -uo pipefail

QUESTION_ID="q116-07-longest-prefix-wins${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Ingress 'zenith' exists in $QUESTION_ID, host zenith.local" \
  bash -c "kubectl get ingress zenith -n '$QUESTION_ID' >/dev/null 2>&1 && \
    [ \"\$(kubectl get ingress zenith -n '$QUESTION_ID' -o jsonpath='{.spec.rules[0].host}')\" = 'zenith.local' ]"

check_criterion "Ingress has exactly 2 path rules, both pathType Prefix" \
  bash -c "kubectl get ingress zenith -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e '(.spec.rules[0].http.paths | length) == 2 and (.spec.rules[0].http.paths | map(.pathType) | all(. == \"Prefix\"))' >/dev/null"

check_criterion "Path '/api' routes to v1-svc:80" \
  bash -c "kubectl get ingress zenith -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e '[.spec.rules[0].http.paths[]? | select(.path == \"/api\" and .backend.service.name == \"v1-svc\" and .backend.service.port.number == 80)] | length == 1' >/dev/null"

check_criterion "Path '/api/v2' routes to v2-svc:80" \
  bash -c "kubectl get ingress zenith -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e '[.spec.rules[0].http.paths[]? | select(.path == \"/api/v2\" and .backend.service.name == \"v2-svc\" and .backend.service.port.number == 80)] | length == 1' >/dev/null"

check_criterion "No defaultBackend is set" \
  bash -c "kubectl get ingress zenith -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e '.spec.defaultBackend == null' >/dev/null"

print_score
