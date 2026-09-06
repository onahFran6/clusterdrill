#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q108-12-ingress-tls${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Ingress 'secure-ingress' exists in $QUESTION_ID" \
  resource_exists ingress secure-ingress -n "$QUESTION_ID"

check_criterion "Ingress 'secure-ingress' uses IngressClass nginx" \
  [ "$(kget ingress secure-ingress '{.spec.ingressClassName}' -n "$QUESTION_ID")" = "nginx" ]

check_criterion "Host secure.ckad.example.com routes to secure-app-svc:80" \
  bash -c "kubectl get ingress secure-ingress -n '$QUESTION_ID' \
      -o jsonpath='{range .spec.rules[?(@.host==\"secure.ckad.example.com\")].http.paths[*]}{.backend.service.name}:{.backend.service.port.number}{end}' \
      | grep -qx 'secure-app-svc:80'"

check_criterion "Ingress tls block covers secure.ckad.example.com" \
  bash -c "kubectl get ingress secure-ingress -n '$QUESTION_ID' -o jsonpath='{.spec.tls[*].hosts[*]}' | grep -qw 'secure.ckad.example.com'"

check_criterion "Ingress tls block references Secret 'secure-app-tls'" \
  bash -c "kubectl get ingress secure-ingress -n '$QUESTION_ID' -o jsonpath='{.spec.tls[*].secretName}' | grep -qw 'secure-app-tls'"

print_score
