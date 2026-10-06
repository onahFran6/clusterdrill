#!/usr/bin/env bash
# Spec-only checks, same rationale as every other Ingress question in this
# bank: this cluster has no Ingress controller installed, so only the
# object's fields are asserted, never a live HTTP response through one.
set -uo pipefail

QUESTION_ID="q113-11-ingress-path-routing${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Ingress 'capella' exists, class nginx, one host with exactly 2 paths" \
  bash -c "kubectl get ingress capella -n '$QUESTION_ID' >/dev/null 2>&1 && \
    [ \"\$(kubectl get ingress capella -n '$QUESTION_ID' -o jsonpath='{.spec.ingressClassName}')\" = 'nginx' ] && \
    [ \"\$(kubectl get ingress capella -n '$QUESTION_ID' -o jsonpath='{.spec.rules[*].host}' | wc -w | tr -d ' ')\" = '1' ] && \
    [ \"\$(kubectl get ingress capella -n '$QUESTION_ID' -o jsonpath='{.spec.rules[0].http.paths[*].path}' | wc -w | tr -d ' ')\" = '2' ]"

check_criterion "a Prefix path '/shop' routes to shop-svc:80" \
  bash -c "
    for i in 0 1; do
      path=\$(kubectl get ingress capella -n '$QUESTION_ID' -o jsonpath=\"{.spec.rules[0].http.paths[\$i].path}\" 2>/dev/null)
      pt=\$(kubectl get ingress capella -n '$QUESTION_ID' -o jsonpath=\"{.spec.rules[0].http.paths[\$i].pathType}\" 2>/dev/null)
      svc=\$(kubectl get ingress capella -n '$QUESTION_ID' -o jsonpath=\"{.spec.rules[0].http.paths[\$i].backend.service.name}:{.spec.rules[0].http.paths[\$i].backend.service.port.number}\" 2>/dev/null)
      if [ \"\$path\" = '/shop' ] && [ \"\$pt\" = 'Prefix' ] && [ \"\$svc\" = 'shop-svc:80' ]; then exit 0; fi
    done
    exit 1
  "

check_criterion "a Prefix path '/api' routes to api-svc:80" \
  bash -c "
    for i in 0 1; do
      path=\$(kubectl get ingress capella -n '$QUESTION_ID' -o jsonpath=\"{.spec.rules[0].http.paths[\$i].path}\" 2>/dev/null)
      pt=\$(kubectl get ingress capella -n '$QUESTION_ID' -o jsonpath=\"{.spec.rules[0].http.paths[\$i].pathType}\" 2>/dev/null)
      svc=\$(kubectl get ingress capella -n '$QUESTION_ID' -o jsonpath=\"{.spec.rules[0].http.paths[\$i].backend.service.name}:{.spec.rules[0].http.paths[\$i].backend.service.port.number}\" 2>/dev/null)
      if [ \"\$path\" = '/api' ] && [ \"\$pt\" = 'Prefix' ] && [ \"\$svc\" = 'api-svc:80' ]; then exit 0; fi
    done
    exit 1
  "

print_score
