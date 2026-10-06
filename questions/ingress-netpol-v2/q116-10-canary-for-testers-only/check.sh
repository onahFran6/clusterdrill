#!/usr/bin/env bash
# Spec-only checks: this bank's supported-cluster contract does not
# guarantee a working ingress-nginx controller, so only the Ingress
# object's own fields are asserted here, never a live HTTP response.
set -uo pipefail

QUESTION_ID="q116-10-canary-for-testers-only${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Ingress 'comet-canary' exists in $QUESTION_ID" \
  resource_exists ingress comet-canary -n "$QUESTION_ID"

check_criterion "Annotations canary=true and canary-by-header=X-Canary are set" \
  bash -c "kubectl get ingress comet-canary -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e '.metadata.annotations[\"nginx.ingress.kubernetes.io/canary\"] == \"true\" and .metadata.annotations[\"nginx.ingress.kubernetes.io/canary-by-header\"] == \"X-Canary\"' >/dev/null"

check_criterion "Same host and path as 'comet', routed to canary-svc:80" \
  bash -c "comet_host=\$(kubectl get ingress comet -n '$QUESTION_ID' -o jsonpath='{.spec.rules[0].host}' 2>/dev/null); \
    comet_path=\$(kubectl get ingress comet -n '$QUESTION_ID' -o jsonpath='{.spec.rules[0].http.paths[0].path}' 2>/dev/null); \
    kubectl get ingress comet-canary -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e --arg host \"\$comet_host\" --arg path \"\$comet_path\" \
      '.spec.rules[0].host == \$host and ([.spec.rules[0].http.paths[]? | select(.path == \$path and .backend.service.name == \"canary-svc\" and .backend.service.port.number == 80)] | length == 1)' >/dev/null"

print_score
