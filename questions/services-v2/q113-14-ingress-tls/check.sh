#!/usr/bin/env bash
# The Secret/certificate half is graded live (real TLS material, decodable
# independent of any controller). The Ingress routing half is spec-only,
# same rationale as every other Ingress question in this bank: no Ingress
# controller is installed on this cluster.
set -uo pipefail

QUESTION_ID="q113-14-ingress-tls${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Secret 'secure-tls' is type kubernetes.io/tls with non-empty tls.crt and tls.key" \
  bash -c "kubectl get secret secure-tls -n '$QUESTION_ID' >/dev/null 2>&1 && \
    [ \"\$(kubectl get secret secure-tls -n '$QUESTION_ID' -o jsonpath='{.type}')\" = 'kubernetes.io/tls' ] && \
    [ -n \"\$(kubectl get secret secure-tls -n '$QUESTION_ID' -o jsonpath='{.data.tls\.crt}')\" ] && \
    [ -n \"\$(kubectl get secret secure-tls -n '$QUESTION_ID' -o jsonpath='{.data.tls\.key}')\" ]"

check_criterion "Ingress 'secure' declares exactly one TLS host, backed by Secret 'secure-tls'" \
  bash -c "kubectl get ingress secure -n '$QUESTION_ID' >/dev/null 2>&1 && \
    [ \"\$(kubectl get ingress secure -n '$QUESTION_ID' -o jsonpath='{.spec.ingressClassName}')\" = 'nginx' ] && \
    [ \"\$(kubectl get ingress secure -n '$QUESTION_ID' -o jsonpath='{.spec.tls[0].secretName}')\" = 'secure-tls' ] && \
    [ \"\$(kubectl get ingress secure -n '$QUESTION_ID' -o jsonpath='{.spec.tls[0].hosts[*]}' | wc -w | tr -d ' ')\" = '1' ]"

check_criterion "Ingress 'secure' routes / to secure-svc:80" \
  bash -c "
    svc=\$(kubectl get ingress secure -n '$QUESTION_ID' -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}:{.spec.rules[0].http.paths[0].backend.service.port.number}' 2>/dev/null)
    path=\$(kubectl get ingress secure -n '$QUESTION_ID' -o jsonpath='{.spec.rules[0].http.paths[0].path}' 2>/dev/null)
    [ \"\$svc\" = 'secure-svc:80' ] && [ \"\$path\" = '/' ]
  "

check_criterion "functional: the Secret's tls.crt decodes to a real certificate whose CN matches the Ingress's TLS host" \
  bash -c "
    host=\$(kubectl get ingress secure -n '$QUESTION_ID' -o jsonpath='{.spec.tls[0].hosts[0]}' 2>/dev/null)
    [ -n \"\$host\" ] || exit 1
    subject=\$(kubectl get secret secure-tls -n '$QUESTION_ID' -o jsonpath='{.data.tls\.crt}' 2>/dev/null | base64 -d 2>/dev/null | openssl x509 -noout -subject 2>/dev/null)
    cn=\$(echo \"\$subject\" | grep -oE 'CN *= *[^,/]+' | sed -E 's/CN *= *//')
    [ \"\$cn\" = \"\$host\" ]
  "

print_score
