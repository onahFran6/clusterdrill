#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q104-03-rollout-undo-previous${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'search' image reverted to nginx:1.24-alpine" \
  [ "$(kget deployment search '{.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")" = "nginx:1.24-alpine" ]

check_criterion "Deployment 'search' is fully rolled out on the reverted image" \
  bash -c '
    image="$(kubectl get deployment search -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    ready="$(kubectl get deployment search -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    updated="$(kubectl get deployment search -n "'"$QUESTION_ID"'" -o jsonpath="{.status.updatedReplicas}" 2>/dev/null)"
    [ "$image" = "nginx:1.24-alpine" ] && [ "$ready" = "3" ] && [ "$updated" = "3" ]
  '

check_criterion "Deployment 'search' has no unavailable replicas" \
  [ -z "$(kget deployment search '{.status.unavailableReplicas}' -n "$QUESTION_ID")" ]

check_criterion "The current ReplicaSet's revision annotation advanced past revision 2 (an undo, not a manual edit)" \
  bash -c '
    rev="$(kubectl get rs -n "'"$QUESTION_ID"'" -l app=search \
      -o jsonpath="{.items[?(@.spec.replicas>0)].metadata.annotations.deployment\.kubernetes\.io/revision}" 2>/dev/null)"
    [ -n "$rev" ] && [ "$rev" -ge 3 ]
  '

print_score
