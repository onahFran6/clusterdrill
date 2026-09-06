#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q104-06-tune-max-surge-fast-rollout${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'image-resizer' has maxSurge=100%" \
  [ "$(kget deployment image-resizer '{.spec.strategy.rollingUpdate.maxSurge}' -n "$QUESTION_ID")" = "100%" ]

check_criterion "Deployment 'image-resizer' has maxUnavailable=0" \
  [ "$(kget deployment image-resizer '{.spec.strategy.rollingUpdate.maxUnavailable}' -n "$QUESTION_ID")" = "0" ]

check_criterion "Deployment 'image-resizer' image updated to nginx:1.25-alpine" \
  [ "$(kget deployment image-resizer '{.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")" = "nginx:1.25-alpine" ]

check_criterion "Deployment 'image-resizer' rollout completed on the new image with all 6 replicas ready" \
  bash -c '
    image="$(kubectl get deployment image-resizer -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    ready="$(kubectl get deployment image-resizer -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    updated="$(kubectl get deployment image-resizer -n "'"$QUESTION_ID"'" -o jsonpath="{.status.updatedReplicas}" 2>/dev/null)"
    [ "$image" = "nginx:1.25-alpine" ] && [ "$ready" = "6" ] && [ "$updated" = "6" ]
  '

print_score
