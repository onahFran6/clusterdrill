#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q108-41-ingress-wildcard-host-routing${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Ingress 'tenant-portal-ingress' exists in $QUESTION_ID" \
  resource_exists ingress tenant-portal-ingress -n "$QUESTION_ID"

check_criterion "Ingress uses IngressClass nginx" \
  [ "$(kget ingress tenant-portal-ingress '{.spec.ingressClassName}' -n "$QUESTION_ID")" = "nginx" ]

check_criterion "Ingress rule host is the wildcard *.tenants.example.com" \
  [ "$(kget ingress tenant-portal-ingress '{.spec.rules[0].host}' -n "$QUESTION_ID")" = "*.tenants.example.com" ]

check_criterion "Ingress routes / (Prefix) to tenant-portal-svc:80" \
  bash -c "kubectl get ingress tenant-portal-ingress -n '$QUESTION_ID' \
      -o jsonpath='{range .spec.rules[0].http.paths[?(@.path==\"/\")]}{.pathType}:{.backend.service.name}:{.backend.service.port.number}{end}' \
      | grep -qx 'Prefix:tenant-portal-svc:80'"

print_score
