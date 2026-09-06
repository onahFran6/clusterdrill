#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q108-22-add-second-service-port-mapping${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# setup.sh already leaves 'http' (8080->8080) correctly in place, so that
# alone must never score - it's bundled with "exactly 2 named ports" below,
# which only becomes true once the candidate actually adds 'metrics'.
check_criterion "Service 'metrics-agent-svc' has exactly 2 named ports, including 'http' 8080->8080" \
  bash -c "
    names=\$(kubectl get service metrics-agent-svc -n '$QUESTION_ID' -o jsonpath='{.spec.ports[*].name}' 2>/dev/null)
    count=\$(echo -n \"\$names\" | wc -w | tr -d ' ')
    http_port=\$(kubectl get service metrics-agent-svc -n '$QUESTION_ID' -o jsonpath='{.spec.ports[?(@.name==\"http\")].port}' 2>/dev/null)
    http_target=\$(kubectl get service metrics-agent-svc -n '$QUESTION_ID' -o jsonpath='{.spec.ports[?(@.name==\"http\")].targetPort}' 2>/dev/null)
    [ \"\$count\" = '2' ] && [ \"\$http_port\" = '8080' ] && [ \"\$http_target\" = '8080' ]
  "

check_criterion "Service 'metrics-agent-svc' port 'metrics' is 9090 -> 9090" \
  bash -c "
    port=\$(kubectl get service metrics-agent-svc -n '$QUESTION_ID' -o jsonpath='{.spec.ports[?(@.name==\"metrics\")].port}' 2>/dev/null)
    target=\$(kubectl get service metrics-agent-svc -n '$QUESTION_ID' -o jsonpath='{.spec.ports[?(@.name==\"metrics\")].targetPort}' 2>/dev/null)
    [ \"\$port\" = '9090' ] && [ \"\$target\" = '9090' ]
  "

check_criterion "EndpointSlice for metrics-agent-svc lists both 'http' and 'metrics' ports" \
  bash -c "
    ports=\$(kubectl get endpointslice -n '$QUESTION_ID' \
      -l kubernetes.io/service-name=metrics-agent-svc \
      -o jsonpath='{range .items[*]}{range .ports[*]}{.name}{\"\n\"}{end}{end}' 2>/dev/null | sort -u | tr '\n' ' ')
    echo \"\$ports\" | grep -qw 'http' && echo \"\$ports\" | grep -qw 'metrics'
  "

print_score
