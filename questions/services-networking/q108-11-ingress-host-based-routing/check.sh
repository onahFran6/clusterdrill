#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q108-11-ingress-host-based-routing${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Ingress 'sites-ingress' exists in $QUESTION_ID" \
  resource_exists ingress sites-ingress -n "$QUESTION_ID"

check_criterion "Ingress 'sites-ingress' uses IngressClass nginx" \
  [ "$(kget ingress sites-ingress '{.spec.ingressClassName}' -n "$QUESTION_ID")" = "nginx" ]

check_criterion "Host blog.ckad.example.com routes to blog-svc:80" \
  bash -c "kubectl get ingress sites-ingress -n '$QUESTION_ID' \
      -o jsonpath='{range .spec.rules[?(@.host==\"blog.ckad.example.com\")].http.paths[*]}{.backend.service.name}:{.backend.service.port.number}{end}' \
      | grep -qx 'blog-svc:80'"

check_criterion "Host api.ckad.example.com routes to api-svc:8080" \
  bash -c "kubectl get ingress sites-ingress -n '$QUESTION_ID' \
      -o jsonpath='{range .spec.rules[?(@.host==\"api.ckad.example.com\")].http.paths[*]}{.backend.service.name}:{.backend.service.port.number}{end}' \
      | grep -qx 'api-svc:8080'"

check_criterion "Ingress defines exactly 2 host rules" \
  [ "$(kget ingress sites-ingress '{.spec.rules[*].host}' -n "$QUESTION_ID" | wc -w | tr -d ' ')" = "2" ]

print_score
