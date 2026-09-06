#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q108-45-ingress-tls-secretname-mismatch-fix${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Every other fact asserted below (Secret existing/unchanged, host/path
# routing unchanged) is already true right after setup.sh - only the
# secretName fix is not - so every criterion is gated on the fix to keep
# the unsolved state at 0.
SECRET_NAME="$(kget ingress secure-app-ingress '{.spec.tls[0].secretName}' -n "$QUESTION_ID")"
if [ "$SECRET_NAME" = "secure-app-tls" ]; then
  FIXED=0
else
  FIXED=1
fi

check_criterion "Ingress 'secure-app-ingress' tls[0].secretName fixed to 'secure-app-tls'" \
  [ "$FIXED" = "0" ]

check_criterion "Fix applied AND Secret 'secure-app-tls' still exists as a kubernetes.io/tls Secret" \
  bash -c "[ '$FIXED' = '0' ] && \
    kubectl get secret secure-app-tls -n '$QUESTION_ID' >/dev/null 2>&1 && \
    [ \"\$(kubectl get secret secure-app-tls -n '$QUESTION_ID' -o jsonpath='{.type}')\" = 'kubernetes.io/tls' ]"

check_criterion "Fix applied AND Ingress host/path routing to secure-app-svc:80 unchanged" \
  bash -c "[ '$FIXED' = '0' ] && \
    [ \"\$(kubectl get ingress secure-app-ingress -n '$QUESTION_ID' -o jsonpath='{.spec.rules[0].host}')\" = 'secure.ckad.example.com' ] && \
    kubectl get ingress secure-app-ingress -n '$QUESTION_ID' \
      -o jsonpath='{range .spec.rules[0].http.paths[?(@.path==\"/\")]}{.backend.service.name}:{.backend.service.port.number}{end}' \
      | grep -qx 'secure-app-svc:80'"

print_score
