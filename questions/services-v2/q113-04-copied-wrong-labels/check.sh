#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q113-04-copied-wrong-labels${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Service 'ledger-svc' selector is exactly {app: ledger-api, tier: backend}" \
  bash -c "[ \"\$(kubectl get service ledger-svc -n '$QUESTION_ID' -o jsonpath='{.spec.selector.app}')\" = 'ledger-api' ] && \
    [ \"\$(kubectl get service ledger-svc -n '$QUESTION_ID' -o jsonpath='{.spec.selector.tier}')\" = 'backend' ]"

check_criterion "Service 'ledger-svc' targetPort is 80" \
  [ "$(kget service ledger-svc '{.spec.ports[0].targetPort}' -n "$QUESTION_ID")" = "80" ]

check_criterion "functional: endpoints for ledger-svc settle at 3 addresses" \
  bash -c "
    for i in 1 2 3 4 5 6; do
      n=\$(kubectl get endpointslices -n '$QUESTION_ID' -l kubernetes.io/service-name=ledger-svc \
        -o jsonpath='{range .items[*].endpoints[*]}{.addresses[0]}{\"\n\"}{end}' 2>/dev/null | grep -c .)
      if [ \"\$n\" = '3' ]; then exit 0; fi
      sleep 2
    done
    exit 1
  "

check_criterion "functional: ledger-svc returns the nginx page" \
  bash -c "kubectl run tmp-q113-04-fn --rm -i --restart=Never --image=busybox:1.36 -n '$QUESTION_ID' -- \
    sh -c 'i=0; while [ \$i -lt 6 ]; do out=\$(wget -qO- -T 3 http://ledger-svc 2>/dev/null); \
    if echo \"\$out\" | grep -q \"<title>\"; then exit 0; fi; i=\$((i+1)); sleep 2; done; exit 1'"

print_score
