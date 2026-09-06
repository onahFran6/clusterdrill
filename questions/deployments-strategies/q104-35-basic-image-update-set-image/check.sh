#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q104-35-basic-image-update-set-image${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# 'web-cache' already exists (redis:7.2-alpine, 3/3 ready) by the time the
# candidate connects, so every criterion is gated on the new image actually
# being live, not just "exists"/"3 ready" which would trivially pass pre-solve.

check_criterion "Deployment 'web-cache' image updated to redis:7.4-alpine" \
  [ "$(kget deployment web-cache '{.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")" = "redis:7.4-alpine" ]

check_criterion "Deployment 'web-cache' rollout completed: 3 ready and 3 updated on the new image" \
  bash -c '
    image="$(kubectl get deployment web-cache -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    ready="$(kubectl get deployment web-cache -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    updated="$(kubectl get deployment web-cache -n "'"$QUESTION_ID"'" -o jsonpath="{.status.updatedReplicas}" 2>/dev/null)"
    [ "$image" = "redis:7.4-alpine" ] && [ "$ready" = "3" ] && [ "$updated" = "3" ]
  '

print_score
