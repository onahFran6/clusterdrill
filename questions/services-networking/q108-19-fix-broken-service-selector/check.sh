#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q108-19-fix-broken-service-selector${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Service 'notification-worker-svc' selector matches app=notification-worker" \
  [ "$(kget service notification-worker-svc '{.spec.selector.app}' -n "$QUESTION_ID")" = "notification-worker" ]

check_criterion "Service now has ready endpoints" \
  bash -c "ips=\$(kubectl get endpoints notification-worker-svc -n '$QUESTION_ID' -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null); [ -n \"\$ips\" ]"

check_criterion "Service has exactly 2 ready endpoints (matches replica count)" \
  bash -c "count=\$(kubectl get endpoints notification-worker-svc -n '$QUESTION_ID' -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null | wc -w | tr -d ' '); [ \"\$count\" = '2' ]"

print_score
