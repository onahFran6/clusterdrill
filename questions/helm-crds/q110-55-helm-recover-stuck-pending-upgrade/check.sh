#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q110-55-helm-recover-stuck-pending-upgrade${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# setup.sh already leaves the release wedged with revision 2 pending and
# revision 1's old ReplicaSet still available (RollingUpdate keeps it
# serving) - so "history has revision 2 pending-upgrade" and "1 replica
# available" are both trivially true before the candidate does anything.
# Gate every criterion on the one thing that can't be true without a real
# fix: the deployment actually running the follow-up image, 1.27-alpine.
IMAGE_NOW="$(kget deployment stuck-stuckapp '{.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")"
FOLLOWUP_LANDED="no"
[ "$IMAGE_NOW" = "nginx:1.27-alpine" ] && FOLLOWUP_LANDED="yes"

check_criterion "A real follow-up upgrade landed: Deployment 'stuck-stuckapp' now runs nginx:1.27-alpine" \
  [ "$FOLLOWUP_LANDED" = "yes" ]

STATUS_JSON="$(helm status stuck -n "$QUESTION_ID" -o json 2>/dev/null)"
IS_DEPLOYED="no"
[ "$FOLLOWUP_LANDED" = "yes" ] && echo "$STATUS_JSON" | grep -q '"status":"deployed"' && IS_DEPLOYED="yes"
check_criterion "Release 'stuck' is 'deployed' (the lock was cleared)" \
  [ "$IS_DEPLOYED" = "yes" ]

FULLY_AVAILABLE="no"
[ "$IS_DEPLOYED" = "yes" ] && [ "$(kget deployment stuck-stuckapp '{.status.availableReplicas}' -n "$QUESTION_ID")" = "1" ] && FULLY_AVAILABLE="yes"
check_criterion "Deployment 'stuck-stuckapp' is fully available on that image" \
  [ "$FULLY_AVAILABLE" = "yes" ]

HISTORY_JSON="$(helm history stuck -n "$QUESTION_ID" -o json 2>/dev/null)"
HISTORY_PRESERVED="no"
if [ "$IS_DEPLOYED" = "yes" ] && echo "$HISTORY_JSON" | grep -q '"revision":2,"updated":"[^"]*","status":"pending-upgrade"'; then
  HISTORY_PRESERVED="yes"
fi
check_criterion "Release history still lists revision 2 as pending-upgrade (history not discarded)" \
  [ "$HISTORY_PRESERVED" = "yes" ]

print_score
