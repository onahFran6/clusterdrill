#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q113-20-loadbalancer-pending-port-forward${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Service 'gate' is type LoadBalancer" \
  [ "$(kget service gate '{.spec.type}' -n "$QUESTION_ID")" = "LoadBalancer" ]

check_criterion "Service 'gate' still has a NodePort assigned in 30000-32767 underneath the LoadBalancer type" \
  bash -c "
    np=\$(kubectl get service gate -n '$QUESTION_ID' -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
    [ -n \"\$np\" ] && [ \"\$np\" -ge 30000 ] && [ \"\$np\" -le 32767 ]
  "

print_score
