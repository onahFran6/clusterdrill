#!/usr/bin/env bash
# The Secret/certificate half is graded live (real TLS material, decodable
# independent of any controller). The Ingress routing half is spec-only,
# same rationale as every other Ingress question in this bank: this
# cluster's supported-cluster contract does not guarantee a working
# Ingress controller.
set -uo pipefail

QUESTION_ID="q116-08-two-hosts-two-certificates${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

for pair in "alpha-tls" "beta-tls"; do
  check_criterion "Secret '$pair' is type kubernetes.io/tls with non-empty tls.crt and tls.key" \
    bash -c "kubectl get secret '$pair' -n '$QUESTION_ID' >/dev/null 2>&1 && \
      [ \"\$(kubectl get secret '$pair' -n '$QUESTION_ID' -o jsonpath='{.type}')\" = 'kubernetes.io/tls' ] && \
      [ -n \"\$(kubectl get secret '$pair' -n '$QUESTION_ID' -o jsonpath='{.data.tls\.crt}')\" ] && \
      [ -n \"\$(kubectl get secret '$pair' -n '$QUESTION_ID' -o jsonpath='{.data.tls\.key}')\" ]"
done

check_criterion "Ingress 'orbit' declares spec.tls with 2 entries, each pairing a host with its own Secret" \
  bash -c "kubectl get ingress orbit -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e '(.spec.tls | length) == 2 and \
      ([.spec.tls[] | select(.hosts == [\"a.orbit.local\"] and .secretName == \"alpha-tls\")] | length == 1) and \
      ([.spec.tls[] | select(.hosts == [\"b.orbit.local\"] and .secretName == \"beta-tls\")] | length == 1)' >/dev/null"

check_criterion "Ingress 'orbit' routes a.orbit.local/ to alpha-svc:80 and b.orbit.local/ to beta-svc:80" \
  bash -c "kubectl get ingress orbit -n '$QUESTION_ID' -o json 2>/dev/null | \
    jq -e '([.spec.rules[] | select(.host == \"a.orbit.local\") | .http.paths[] | select(.path == \"/\" and .backend.service.name == \"alpha-svc\" and .backend.service.port.number == 80)] | length == 1) and \
      ([.spec.rules[] | select(.host == \"b.orbit.local\") | .http.paths[] | select(.path == \"/\" and .backend.service.name == \"beta-svc\" and .backend.service.port.number == 80)] | length == 1)' >/dev/null"

check_criterion "functional: each Secret's tls.crt decodes to a real certificate whose CN matches its own host" \
  bash -c "
    alpha_subject=\$(kubectl get secret alpha-tls -n '$QUESTION_ID' -o jsonpath='{.data.tls\.crt}' 2>/dev/null | base64 -d 2>/dev/null | openssl x509 -noout -subject 2>/dev/null)
    alpha_cn=\$(echo \"\$alpha_subject\" | grep -oE 'CN *= *[^,/]+' | sed -E 's/CN *= *//')
    beta_subject=\$(kubectl get secret beta-tls -n '$QUESTION_ID' -o jsonpath='{.data.tls\.crt}' 2>/dev/null | base64 -d 2>/dev/null | openssl x509 -noout -subject 2>/dev/null)
    beta_cn=\$(echo \"\$beta_subject\" | grep -oE 'CN *= *[^,/]+' | sed -E 's/CN *= *//')
    [ \"\$alpha_cn\" = 'a.orbit.local' ] && [ \"\$beta_cn\" = 'b.orbit.local' ]
  "

print_score
