#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q108-24-ingress-rewrite-target-annotation${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Ingress 'shop-ingress' has rewrite-target annotation '/', capture-group path '/api(/|\$)(.*)' with pathType ImplementationSpecific, and still routes to shop-api-svc:80" \
  bash -c "
    ann=\$(kubectl get ingress shop-ingress -n '$QUESTION_ID' \
        -o jsonpath='{.metadata.annotations.nginx\.ingress\.kubernetes\.io/rewrite-target}' 2>/dev/null)
    path=\$(kubectl get ingress shop-ingress -n '$QUESTION_ID' \
        -o jsonpath='{.spec.rules[0].http.paths[0].path}' 2>/dev/null)
    backend=\$(kubectl get ingress shop-ingress -n '$QUESTION_ID' \
        -o jsonpath='{.spec.rules[0].http.paths[0].pathType}:{.spec.rules[0].http.paths[0].backend.service.name}:{.spec.rules[0].http.paths[0].backend.service.port.number}' 2>/dev/null)
    [ \"\$ann\" = '/' ] && [ \"\$path\" = '/api(/|\$)(.*)' ] && [ \"\$backend\" = 'ImplementationSpecific:shop-api-svc:80' ]
  "

print_score
