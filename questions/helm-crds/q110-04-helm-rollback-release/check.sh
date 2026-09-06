#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q110-04-helm-rollback-release${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# setup.sh already leaves a Deployment named 'svc-api' behind (broken, at
# revision 2), and the rolling update can leave the old, working ReplicaSet
# briefly serving traffic too - so "exists" / "is available" alone would be
# trivially true before the candidate does anything. Only assert things
# that require the actual rollback: the image is back to the known-good tag
# AND that same generation is what's available, plus the revision advanced.
IMAGE_NOW="$(kget deployment svc-api '{.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")"

check_criterion "Deployment 'svc-api' spec image is nginx:1.25-alpine again" \
  [ "$IMAGE_NOW" = "nginx:1.25-alpine" ]

GOOD_AND_AVAILABLE="no"
if [ "$IMAGE_NOW" = "nginx:1.25-alpine" ] && \
   [ "$(kget deployment svc-api '{.status.availableReplicas}' -n "$QUESTION_ID")" = "1" ] && \
   [ "$(kget deployment svc-api '{.status.updatedReplicas}' -n "$QUESTION_ID")" = "1" ]; then
  GOOD_AND_AVAILABLE="yes"
fi
check_criterion "Deployment 'svc-api' fully rolled out on the restored image" \
  [ "$GOOD_AND_AVAILABLE" = "yes" ]

RELEASE_STATUS="$(helm status svc -n "$QUESTION_ID" -o json 2>/dev/null)"
REVISION_NUM="$(echo "$RELEASE_STATUS" | grep -o '"version":[0-9]*' | head -1 | cut -d: -f2)"
REVISION_NUM="${REVISION_NUM:-0}"
check_criterion "Release 'svc' advanced to revision 3 (a rollback, not a manual edit)" \
  [ "$REVISION_NUM" -ge 3 ]

print_score
