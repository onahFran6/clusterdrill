#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q111-05-rollout-restart-stale-env${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "A running 'greeter' pod reports GREETING=hola" \
  bash -c '
    pod="$(newest_pod_name "'"$QUESTION_ID"'" app=greeter)"
    [ -n "$pod" ] && [ "$(kubectl exec "$pod" -n "'"$QUESTION_ID"'" -- printenv GREETING 2>/dev/null)" = "hola" ]
  '

check_criterion "A real rollout carried the fix (revision 2, not a delete/recreate)" \
  [ "$(kget deployment greeter '{.metadata.annotations.deployment\.kubernetes\.io/revision}' -n "$QUESTION_ID")" = "2" ]

print_score
