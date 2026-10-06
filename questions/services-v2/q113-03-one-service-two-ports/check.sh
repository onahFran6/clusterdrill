#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q113-03-one-service-two-ports${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Service 'shop-svc' exists with exactly 2 ports" \
  bash -c "kubectl get service shop-svc -n '$QUESTION_ID' >/dev/null 2>&1 && \
    [ \"\$(kubectl get service shop-svc -n '$QUESTION_ID' -o jsonpath='{.spec.ports[*].port}' | wc -w | tr -d ' ')\" = '2' ]"

check_criterion "port 80 targets container port by name 'http'" \
  bash -c "
    for i in 0 1; do
      p=\$(kubectl get service shop-svc -n '$QUESTION_ID' -o jsonpath=\"{.spec.ports[\$i].port}\" 2>/dev/null)
      tp=\$(kubectl get service shop-svc -n '$QUESTION_ID' -o jsonpath=\"{.spec.ports[\$i].targetPort}\" 2>/dev/null)
      if [ \"\$p\" = '80' ] && [ \"\$tp\" = 'http' ]; then exit 0; fi
    done
    exit 1
  "

check_criterion "port 9100 targets container port by name 'metrics'" \
  bash -c "
    for i in 0 1; do
      p=\$(kubectl get service shop-svc -n '$QUESTION_ID' -o jsonpath=\"{.spec.ports[\$i].port}\" 2>/dev/null)
      tp=\$(kubectl get service shop-svc -n '$QUESTION_ID' -o jsonpath=\"{.spec.ports[\$i].targetPort}\" 2>/dev/null)
      if [ \"\$p\" = '9100' ] && [ \"\$tp\" = 'metrics' ]; then exit 0; fi
    done
    exit 1
  "

check_criterion "functional: shop-svc:9100 returns the metrics content" \
  bash -c "kubectl run tmp-q113-03-fn --rm -i --restart=Never --image=busybox:1.36 -n '$QUESTION_ID' -- \
    sh -c 'i=0; while [ \$i -lt 6 ]; do out=\$(wget -qO- -T 3 http://shop-svc:9100 2>/dev/null); \
    if echo \"\$out\" | grep -q \"requests_total 42\"; then exit 0; fi; i=\$((i+1)); sleep 2; done; exit 1'"

print_score
