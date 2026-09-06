#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q104-04-rollout-undo-to-revision${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'billing' image reverted to nginx:1.23-alpine" \
  [ "$(kget deployment billing '{.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")" = "nginx:1.23-alpine" ]

check_criterion "Deployment 'billing' is fully rolled out on the reverted image" \
  bash -c '
    image="$(kubectl get deployment billing -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    ready="$(kubectl get deployment billing -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    updated="$(kubectl get deployment billing -n "'"$QUESTION_ID"'" -o jsonpath="{.status.updatedReplicas}" 2>/dev/null)"
    [ "$image" = "nginx:1.23-alpine" ] && [ "$ready" = "2" ] && [ "$updated" = "2" ]
  '

check_criterion "Current live ReplicaSet's revision annotation advanced past revision 3" \
  bash -c '
    rev="$(kubectl get rs -n "'"$QUESTION_ID"'" -l app=billing \
      -o jsonpath="{.items[?(@.spec.replicas>0)].metadata.annotations.deployment\.kubernetes\.io/revision}" 2>/dev/null)"
    [ -n "$rev" ] && [ "$rev" -ge 4 ]
  '

print_score
