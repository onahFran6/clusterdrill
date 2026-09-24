#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q110-54-helm-upgrade-install-atomic-rollback${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# setup.sh already leaves 'api-atomicapp' healthy on nginx:1.25-alpine at
# revision 1 - so "image is nginx:1.25-alpine" alone would be trivially
# true before the candidate does anything. Every criterion below is gated
# on the release having actually advanced past revision 1, so an unsolved
# namespace scores 0 rather than a false positive.
REVISION_COUNT="$(helm history api -n "$QUESTION_ID" -o json 2>/dev/null | grep -o '"revision":[0-9]*' | wc -l | tr -d ' ')"
ATTEMPTED="no"
[ "${REVISION_COUNT:-0}" -ge 3 ] && ATTEMPTED="yes"

check_criterion "Release history shows a real attempt-and-rollback (at least 3 revisions)" \
  [ "$ATTEMPTED" = "yes" ]

IMAGE_NOW="$(kget deployment api-atomicapp '{.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")"
IMAGE_RESTORED="no"
[ "$ATTEMPTED" = "yes" ] && [ "$IMAGE_NOW" = "nginx:1.25-alpine" ] && IMAGE_RESTORED="yes"
check_criterion "Deployment 'api-atomicapp' is back on nginx:1.25-alpine after the attempt" \
  [ "$IMAGE_RESTORED" = "yes" ]

GOOD_AND_AVAILABLE="no"
if [ "$IMAGE_RESTORED" = "yes" ] && \
   [ "$(kget deployment api-atomicapp '{.status.availableReplicas}' -n "$QUESTION_ID")" = "1" ] && \
   [ "$(kget deployment api-atomicapp '{.status.updatedReplicas}' -n "$QUESTION_ID")" = "1" ]; then
  GOOD_AND_AVAILABLE="yes"
fi
check_criterion "Deployment 'api-atomicapp' fully rolled out on the restored image" \
  [ "$GOOD_AND_AVAILABLE" = "yes" ]

STATUS_JSON="$(helm status api -n "$QUESTION_ID" -o json 2>/dev/null)"
IS_DEPLOYED="no"
[ "$ATTEMPTED" = "yes" ] && echo "$STATUS_JSON" | grep -q '"status":"deployed"' && IS_DEPLOYED="yes"
check_criterion "Release 'api' status is 'deployed' (not left 'failed')" \
  [ "$IS_DEPLOYED" = "yes" ]

print_score
