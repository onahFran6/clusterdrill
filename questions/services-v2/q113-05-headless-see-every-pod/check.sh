#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q113-05-headless-see-every-pod${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Service 'cache-headless' exists with no cluster IP, selecting the 'cache' pods" \
  bash -c "kubectl get service cache-headless -n '$QUESTION_ID' >/dev/null 2>&1 && \
    [ \"\$(kubectl get service cache-headless -n '$QUESTION_ID' -o jsonpath='{.spec.clusterIP}')\" = 'None' ] && \
    [ \"\$(kubectl get service cache-headless -n '$QUESTION_ID' -o jsonpath='{.spec.selector.app}')\" = 'cache' ]"

check_criterion "functional: DNS for cache-svc resolves to exactly 1 address, cache-headless to exactly 3" \
  bash -c "kubectl run tmp-q113-05-fn --rm -i --restart=Never --image=busybox:1.36 -n '$QUESTION_ID' -- \
    sh -c 'i=0; while [ \$i -lt 6 ]; do \
    n1=\$(nslookup cache-svc 2>/dev/null | grep -cE \"^Address: [0-9]+\\.\"); \
    n2=\$(nslookup cache-headless 2>/dev/null | grep -cE \"^Address: [0-9]+\\.\"); \
    if [ \"\$n1\" = \"1\" ] && [ \"\$n2\" = \"3\" ]; then exit 0; fi; \
    i=\$((i+1)); sleep 2; done; exit 1'"

print_score
