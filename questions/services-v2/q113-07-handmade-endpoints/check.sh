#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q113-07-handmade-endpoints${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Service 'legacy-svc' exists, no selector, port {name: http, port: 80}" \
  bash -c "kubectl get service legacy-svc -n '$QUESTION_ID' >/dev/null 2>&1 && \
    [ -z \"\$(kubectl get service legacy-svc -n '$QUESTION_ID' -o jsonpath='{.spec.selector}')\" ] && \
    [ \"\$(kubectl get service legacy-svc -n '$QUESTION_ID' -o jsonpath='{.spec.ports[0].name}')\" = 'http' ] && \
    [ \"\$(kubectl get service legacy-svc -n '$QUESTION_ID' -o jsonpath='{.spec.ports[0].port}')\" = '80' ]"

LEGACY_IP="$(kubectl get pod legacy -n "$QUESTION_ID" -o jsonpath='{.status.podIP}' 2>/dev/null)"
check_criterion "an EndpointSlice labeled for 'legacy-svc' targets the legacy pod's real IP on port 80/http" \
  bash -c "
    for es in \$(kubectl get endpointslices -n '$QUESTION_ID' -l kubernetes.io/service-name=legacy-svc -o name 2>/dev/null); do
      portname=\$(kubectl get -n '$QUESTION_ID' \"\$es\" -o jsonpath='{.ports[0].name}' 2>/dev/null)
      port=\$(kubectl get -n '$QUESTION_ID' \"\$es\" -o jsonpath='{.ports[0].port}' 2>/dev/null)
      addrs=\$(kubectl get -n '$QUESTION_ID' \"\$es\" -o jsonpath='{.endpoints[*].addresses[*]}' 2>/dev/null)
      if [ \"\$portname\" = 'http' ] && [ \"\$port\" = '80' ] && echo \"\$addrs\" | grep -qw \"$LEGACY_IP\"; then exit 0; fi
    done
    exit 1
  "

check_criterion "functional: legacy-svc returns the legacy pod's response" \
  bash -c "kubectl run tmp-q113-07-fn --rm -i --restart=Never --image=busybox:1.36 -n '$QUESTION_ID' -- \
    sh -c 'i=0; while [ \$i -lt 6 ]; do out=\$(wget -qO- -T 3 legacy-svc 2>/dev/null); \
    if echo \"\$out\" | grep -q \"legacy server ok\"; then exit 0; fi; i=\$((i+1)); sleep 2; done; exit 1'"

print_score
