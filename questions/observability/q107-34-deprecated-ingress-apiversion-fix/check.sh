#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q107-34-deprecated-ingress-apiversion-fix${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Ingress 'storefront-ingress' exists on the current networking.k8s.io/v1 API and routes host storefront.example.com, path / to storefront-svc:80" \
  bash -c '
    kubectl get ingress storefront-ingress -n "'"$QUESTION_ID"'" >/dev/null 2>&1 || exit 1
    host="$(kubectl get ingress storefront-ingress -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.rules[0].host}" 2>/dev/null)"
    [ "$host" = "storefront.example.com" ] || exit 1
    path="$(kubectl get ingress storefront-ingress -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.rules[0].http.paths[0].path}" 2>/dev/null)"
    [ "$path" = "/" ] || exit 1
    svc="$(kubectl get ingress storefront-ingress -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.rules[0].http.paths[0].backend.service.name}" 2>/dev/null)"
    [ "$svc" = "storefront-svc" ] || exit 1
    port="$(kubectl get ingress storefront-ingress -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.rules[0].http.paths[0].backend.service.port.number}" 2>/dev/null)"
    [ "$port" = "80" ] || exit 1
    pathtype="$(kubectl get ingress storefront-ingress -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.rules[0].http.paths[0].pathType}" 2>/dev/null)"
    [ -n "$pathtype" ]
  '

print_score
