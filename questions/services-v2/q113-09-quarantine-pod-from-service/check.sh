#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q113-09-quarantine-pod-from-service${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "exactly 4 pods exist in the namespace (3 serving + 1 quarantined)" \
  bash -c "[ \"\$(kubectl get pods -n '$QUESTION_ID' --no-headers 2>/dev/null | wc -l | tr -d ' ')\" = '4' ]"

check_criterion "exactly one Running pod no longer carries the Deployment's 'app=menu' label" \
  bash -c "[ \"\$(kubectl get pods -n '$QUESTION_ID' -l 'app!=menu' --no-headers 2>/dev/null | wc -l | tr -d ' ')\" = '1' ]"

check_criterion "functional: 4 pods total, one quarantined, AND menu-svc endpoints settle at exactly 3" \
  bash -c "
    for i in 1 2 3 4 5 6; do
      total=\$(kubectl get pods -n '$QUESTION_ID' --no-headers 2>/dev/null | wc -l | tr -d ' ')
      quarantined=\$(kubectl get pods -n '$QUESTION_ID' -l 'app!=menu' --no-headers 2>/dev/null | wc -l | tr -d ' ')
      n=\$(kubectl get endpointslices -n '$QUESTION_ID' -l kubernetes.io/service-name=menu-svc \
        -o jsonpath='{range .items[*].endpoints[*]}{.addresses[0]}{\"\n\"}{end}' 2>/dev/null | grep -c .)
      if [ \"\$total\" = '4' ] && [ \"\$quarantined\" = '1' ] && [ \"\$n\" = '3' ]; then exit 0; fi
      sleep 2
    done
    exit 1
  "

print_score
