#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q110-39-helm-broken-posthook-fix${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

STATUS_JSON="$(helm status demo -n "$QUESTION_ID" -o json 2>/dev/null)"
IS_DEPLOYED="no"
echo "$STATUS_JSON" | grep -q '"status":"deployed"' && IS_DEPLOYED="yes"

check_criterion "Release 'demo' status is 'deployed' (not left 'failed')" \
  [ "$IS_DEPLOYED" = "yes" ]

# The Deployment is already Running right after setup.sh (only the
# post-install hook is broken) - gated on the release fix above so the
# unsolved state can't score here.
check_criterion "Fix applied AND Deployment 'demo-notifier' has 1 available replica" \
  bash -c "[ '$IS_DEPLOYED' = 'yes' ] && [ \"\$(kubectl get deployment demo-notifier -n '$QUESTION_ID' -o jsonpath='{.status.availableReplicas}')\" = '1' ]"

check_criterion "Fix applied AND post-install hook Job 'demo-notifier-posthook' completed successfully" \
  bash -c "[ '$IS_DEPLOYED' = 'yes' ] && [ \"\$(kubectl get job demo-notifier-posthook -n '$QUESTION_ID' -o jsonpath='{.status.succeeded}')\" = '1' ]"

print_score
