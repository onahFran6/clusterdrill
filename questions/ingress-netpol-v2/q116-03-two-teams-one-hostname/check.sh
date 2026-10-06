#!/usr/bin/env bash
# Spec-only checks: this bank's supported-cluster contract does not
# guarantee a working ingress-nginx controller, so only the Ingress
# objects' own fields are asserted here, never a live HTTP response.
set -uo pipefail

QUESTION_ID="q116-03-two-teams-one-hostname${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
BLOG_NS="${QUESTION_ID}-blog"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Ingress 'shop' exists in $QUESTION_ID, host nebula.local" \
  bash -c "kubectl get ingress shop -n '$QUESTION_ID' >/dev/null 2>&1 && \
    [ \"\$(kubectl get ingress shop -n '$QUESTION_ID' -o jsonpath='{.spec.rules[0].host}')\" = 'nebula.local' ]"

check_criterion "Ingress 'shop' routes /shop (Prefix) to shop-svc:80" \
  bash -c "kubectl get ingress shop -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e '[.spec.rules[0].http.paths[]? | select(.path == \"/shop\" and .pathType == \"Prefix\" and .backend.service.name == \"shop-svc\" and .backend.service.port.number == 80)] | length == 1' >/dev/null"

check_criterion "Ingress 'blog' exists in $BLOG_NS, host nebula.local" \
  bash -c "kubectl get ingress blog -n '$BLOG_NS' >/dev/null 2>&1 && \
    [ \"\$(kubectl get ingress blog -n '$BLOG_NS' -o jsonpath='{.spec.rules[0].host}')\" = 'nebula.local' ]"

check_criterion "Ingress 'blog' routes /blog (Prefix) to blog-svc:80" \
  bash -c "kubectl get ingress blog -n '$BLOG_NS' -o json 2>/dev/null | \
    jq -e '[.spec.rules[0].http.paths[]? | select(.path == \"/blog\" and .pathType == \"Prefix\" and .backend.service.name == \"blog-svc\" and .backend.service.port.number == 80)] | length == 1' >/dev/null"

print_score
