#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q108-13-ingress-default-backend${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Ingress 'docs-ingress' exists in $QUESTION_ID" \
  resource_exists ingress docs-ingress -n "$QUESTION_ID"

check_criterion "Ingress 'docs-ingress' uses IngressClass nginx" \
  [ "$(kget ingress docs-ingress '{.spec.ingressClassName}' -n "$QUESTION_ID")" = "nginx" ]

check_criterion "Path /docs routes to docs-svc:80" \
  bash -c "kubectl get ingress docs-ingress -n '$QUESTION_ID' \
      -o jsonpath='{range .spec.rules[*].http.paths[?(@.path==\"/docs\")]}{.backend.service.name}:{.backend.service.port.number}{end}' \
      | grep -qx 'docs-svc:80'"

check_criterion "defaultBackend points at fallback-svc:80" \
  bash -c "[ \"\$(kubectl get ingress docs-ingress -n '$QUESTION_ID' -o jsonpath='{.spec.defaultBackend.service.name}')\" = 'fallback-svc' ] && \
    [ \"\$(kubectl get ingress docs-ingress -n '$QUESTION_ID' -o jsonpath='{.spec.defaultBackend.service.port.number}')\" = '80' ]"

print_score
