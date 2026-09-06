#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q108-30-ingress-multiple-backends-wrong-service-port-name${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# The actual bug: the /pay backend's service.port.name ("http") does not
# match any name on payments-svc's spec.ports ("http-api"). This is false
# immediately after setup.sh and only becomes true once the candidate fixes
# the Ingress backend to reference a port name/number that really exists.
#
# The Service's own port is bundled into this SAME criterion (not asserted
# on its own) because setup.sh already leaves it correct - a standalone
# "Service port name is http-api" check would trivially pass unsolved.
# Bundling also enforces "fix the Ingress, not the Service": if the
# candidate instead renamed the Service's port to "http" to match the
# broken Ingress reference, this criterion still fails.
check_criterion "Ingress 'payments-ingress' /pay backend references a port that exists on payments-svc (name http-api or number 80), and payments-svc's port is unchanged" \
  bash -c "
    svc_port_name=\$(kubectl get service payments-svc -n '$QUESTION_ID' -o jsonpath='{.spec.ports[0].name}' 2>/dev/null)
    svc_port_number=\$(kubectl get service payments-svc -n '$QUESTION_ID' -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)
    [ \"\$svc_port_name\" = 'http-api' ] || exit 1
    [ \"\$svc_port_number\" = '80' ] || exit 1

    backend_name=\$(kubectl get ingress payments-ingress -n '$QUESTION_ID' \
        -o jsonpath='{range .spec.rules[*].http.paths[?(@.path==\"/pay\")]}{.backend.service.port.name}{end}' 2>/dev/null)
    backend_number=\$(kubectl get ingress payments-ingress -n '$QUESTION_ID' \
        -o jsonpath='{range .spec.rules[*].http.paths[?(@.path==\"/pay\")]}{.backend.service.port.number}{end}' 2>/dev/null)

    [ \"\$backend_name\" = 'http-api' ] || [ \"\$backend_number\" = '80' ]
  "

# Functional check bundled with the same port-resolution requirement: the
# backend Service must actually serve traffic AND the Ingress backend must
# reference a real port on it, proving this isn't just a cosmetic field
# edit that happens to also serve traffic on an unrelated port. Exercises
# the same Service:port path the Ingress now (correctly) references,
# without depending on the shared minikube's external ingress reachability.
check_criterion "payments-svc:80 serves traffic from payments-app AND the Ingress /pay backend resolves to it" \
  bash -c "
    backend_name=\$(kubectl get ingress payments-ingress -n '$QUESTION_ID' \
        -o jsonpath='{range .spec.rules[*].http.paths[?(@.path==\"/pay\")]}{.backend.service.port.name}{end}' 2>/dev/null)
    backend_number=\$(kubectl get ingress payments-ingress -n '$QUESTION_ID' \
        -o jsonpath='{range .spec.rules[*].http.paths[?(@.path==\"/pay\")]}{.backend.service.port.number}{end}' 2>/dev/null)
    { [ \"\$backend_name\" = 'http-api' ] || [ \"\$backend_number\" = '80' ]; } || exit 1

    kubectl run payments-curl-check-$$ --image=curlimages/curl:8.10.1 --restart=Never \
      -n '$QUESTION_ID' --labels='clusterdrill-question=$QUESTION_ID' \
      --command --quiet -- sh -c 'curl -s -o /dev/null -w \"%{http_code}\" http://payments-svc.$QUESTION_ID.svc.cluster.local:80/ > /tmp/code; cat /tmp/code' \
      >/dev/null 2>&1
    kubectl wait --for=jsonpath='{.status.phase}'=Succeeded pod/payments-curl-check-$$ -n '$QUESTION_ID' --timeout=60s >/dev/null 2>&1
    code=\$(kubectl logs pod/payments-curl-check-$$ -n '$QUESTION_ID' 2>/dev/null)
    kubectl delete pod payments-curl-check-$$ -n '$QUESTION_ID' --ignore-not-found --wait=false >/dev/null 2>&1
    [ \"\$code\" = '200' ]
  "

print_score
