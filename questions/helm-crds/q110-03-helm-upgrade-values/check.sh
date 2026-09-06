#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q110-03-helm-upgrade-values${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

RELEASE_STATUS="$(helm status site -n "$QUESTION_ID" -o json 2>/dev/null)"
REVISION_NUM="$(echo "$RELEASE_STATUS" | grep -o '"version":[0-9]*' | head -1 | cut -d: -f2)"
REVISION_NUM="${REVISION_NUM:-0}"

# setup.sh already installs revision 1, so "release exists" would be a
# trivially-true criterion on the unsolved state - only assert things that
# can ONLY become true once the candidate actually upgrades the release.
check_criterion "Release 'site' is at revision 2 or later (upgraded, not reinstalled)" \
  [ "$REVISION_NUM" -ge 2 ]

check_criterion "Deployment 'site-webfront' now runs nginx:1.27-alpine" \
  [ "$(kget deployment site-webfront '{.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")" = "nginx:1.27-alpine" ]

NEW_IMAGE_AVAILABLE="no"
if [ "$(kget deployment site-webfront '{.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")" = "nginx:1.27-alpine" ] && \
   [ "$(kget deployment site-webfront '{.status.availableReplicas}' -n "$QUESTION_ID")" = "1" ]; then
  NEW_IMAGE_AVAILABLE="yes"
fi
check_criterion "Deployment 'site-webfront' running the new image is available" \
  [ "$NEW_IMAGE_AVAILABLE" = "yes" ]

print_score
