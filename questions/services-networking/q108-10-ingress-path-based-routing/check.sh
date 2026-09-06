#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q108-10-ingress-path-based-routing${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Ingress 'shop-ingress' exists in $QUESTION_ID" \
  resource_exists ingress shop-ingress -n "$QUESTION_ID"

check_criterion "Ingress 'shop-ingress' uses IngressClass nginx" \
  [ "$(kget ingress shop-ingress '{.spec.ingressClassName}' -n "$QUESTION_ID")" = "nginx" ]

check_criterion "Ingress has a /catalog path routed to catalog-svc:80" \
  bash -c "kubectl get ingress shop-ingress -n '$QUESTION_ID' \
      -o jsonpath='{range .spec.rules[*].http.paths[?(@.path==\"/catalog\")]}{.backend.service.name}:{.backend.service.port.number}{end}' \
      | grep -qx 'catalog-svc:80'"

check_criterion "Ingress has a /checkout path routed to checkout-svc:80" \
  bash -c "kubectl get ingress shop-ingress -n '$QUESTION_ID' \
      -o jsonpath='{range .spec.rules[*].http.paths[?(@.path==\"/checkout\")]}{.backend.service.name}:{.backend.service.port.number}{end}' \
      | grep -qx 'checkout-svc:80'"

check_criterion "Both Ingress paths use pathType Prefix" \
  bash -c "types=\$(kubectl get ingress shop-ingress -n '$QUESTION_ID' -o jsonpath='{.spec.rules[*].http.paths[*].pathType}'); \
    [ \"\$(echo \$types | tr ' ' '\n' | sort -u | tr '\n' ' ' | xargs)\" = 'Prefix' ]"

print_score
