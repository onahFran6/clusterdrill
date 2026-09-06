#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q107-33-rollout-history-change-cause${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'web-app' image updated to nginx:1.25-alpine and fully rolled out" \
  bash -c '
    image="$(kubectl get deployment web-app -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    [ "$image" = "nginx:1.25-alpine" ] || exit 1
    ready="$(kubectl get deployment web-app -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    [ "$ready" = "1" ]
  '

# Gated on the image update too - an unrelated change-cause annotation on
# its own would be true regardless of whether a real change ever happened,
# so this makes sure the recorded cause actually corresponds to this
# revision, not just any annotation value sitting there.
check_criterion "Deployment 'web-app' records kubernetes.io/change-cause = 'upgrade nginx to 1.25-alpine' for this revision" \
  bash -c '
    image="$(kubectl get deployment web-app -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    [ "$image" = "nginx:1.25-alpine" ] || exit 1
    cause="$(kubectl get deployment web-app -n "'"$QUESTION_ID"'" -o jsonpath="{.metadata.annotations.kubernetes\.io/change-cause}" 2>/dev/null)"
    [ "$cause" = "upgrade nginx to 1.25-alpine" ]
  '

print_score
