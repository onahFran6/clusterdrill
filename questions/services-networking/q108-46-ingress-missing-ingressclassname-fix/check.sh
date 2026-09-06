#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q108-46-ingress-missing-ingressclassname-fix${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Host/path/backend are already correct right after setup.sh - only
# ingressClassName is broken - so the second criterion is gated on the fix
# to keep the unsolved state at 0.
CLASS_NAME="$(kget ingress reports-ingress '{.spec.ingressClassName}' -n "$QUESTION_ID")"
if [ "$CLASS_NAME" = "nginx" ]; then
  FIXED=0
else
  FIXED=1
fi

check_criterion "Ingress 'reports-ingress' ingressClassName fixed to 'nginx' (an IngressClass that actually exists)" \
  [ "$FIXED" = "0" ]

check_criterion "Fix applied AND Ingress host/path routing to reports-svc:80 unchanged" \
  bash -c "[ '$FIXED' = '0' ] && \
    [ \"\$(kubectl get ingress reports-ingress -n '$QUESTION_ID' -o jsonpath='{.spec.rules[0].host}')\" = 'reports.ckad.example.com' ] && \
    kubectl get ingress reports-ingress -n '$QUESTION_ID' \
      -o jsonpath='{range .spec.rules[0].http.paths[?(@.path==\"/\")]}{.backend.service.name}:{.backend.service.port.number}{end}' \
      | grep -qx 'reports-svc:80'"

print_score
