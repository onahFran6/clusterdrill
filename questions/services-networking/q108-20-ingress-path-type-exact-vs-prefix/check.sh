#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q108-20-ingress-path-type-exact-vs-prefix${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "The /status path is pathType Exact and still routes to status-svc:80" \
  bash -c "kubectl get ingress diagnostics-ingress -n '$QUESTION_ID' \
      -o jsonpath='{range .spec.rules[*].http.paths[?(@.path==\"/status\")]}{.pathType}:{.backend.service.name}:{.backend.service.port.number}{end}' \
      | grep -qx 'Exact:status-svc:80'"

check_criterion "The /metrics path is pathType Prefix and still routes to metrics-svc:80" \
  bash -c "kubectl get ingress diagnostics-ingress -n '$QUESTION_ID' \
      -o jsonpath='{range .spec.rules[*].http.paths[?(@.path==\"/metrics\")]}{.pathType}:{.backend.service.name}:{.backend.service.port.number}{end}' \
      | grep -qx 'Prefix:metrics-svc:80'"

print_score
