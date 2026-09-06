#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q110-32-helm-uninstall-name-reuse${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# "release deployed" and "history has 1 revision" are both already true
# right after setup.sh (the original --set image=busybox:1.36 install is
# itself revision 1, deployed) - only the image marker below actually
# changes when the candidate really uninstalls and reinstalls with
# defaults, so every criterion is gated on that.
IMAGE="$(kget deployment demo-widget '{.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")"
if [ "$IMAGE" = "nginx:1.25-alpine" ]; then
  FIXED=0
else
  FIXED=1
fi

check_criterion "Deployment 'demo-widget' now runs the chart's default image (nginx:1.25-alpine), proving a fresh reinstall happened" \
  [ "$FIXED" = "0" ]

STATUS_JSON="$(helm status demo -n "$QUESTION_ID" -o json 2>/dev/null)"
IS_DEPLOYED="no"
echo "$STATUS_JSON" | grep -q '"status":"deployed"' && IS_DEPLOYED="yes"

check_criterion "Fix applied AND release 'demo' is deployed" \
  bash -c "[ '$FIXED' = '0' ] && [ '$IS_DEPLOYED' = 'yes' ]"

HISTORY_JSON="$(helm history demo -n "$QUESTION_ID" -o json 2>/dev/null)"
REVISION_COUNT="$(echo "$HISTORY_JSON" | grep -o '"revision":[0-9]*' | wc -l | tr -d ' ')"

check_criterion "Fix applied AND 'helm history demo' shows exactly 1 revision (fresh release, not left as the original override)" \
  bash -c "[ '$FIXED' = '0' ] && [ '$REVISION_COUNT' = '1' ]"

check_criterion "Fix applied AND Deployment 'demo-widget' is available" \
  bash -c "[ '$FIXED' = '0' ] && [ \"\$(kubectl get deployment demo-widget -n '$QUESTION_ID' -o jsonpath='{.status.availableReplicas}')\" = '1' ]"

print_score
