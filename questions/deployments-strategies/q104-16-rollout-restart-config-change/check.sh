#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q104-16-rollout-restart-config-change${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'worker-pool' has a restartedAt annotation and unchanged pod template image" \
  bash -c '
    restarted="$(kubectl get deployment worker-pool -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.metadata.annotations.kubectl\.kubernetes\.io/restartedAt}" 2>/dev/null)"
    image="$(kubectl get deployment worker-pool -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    [ -n "$restarted" ] && [ "$image" = "nginx:1.24-alpine" ]
  '

check_criterion "Deployment 'worker-pool' rollout is healthy after the restart: 3 ready, 3 updated" \
  bash -c '
    restarted="$(kubectl get deployment worker-pool -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.metadata.annotations.kubectl\.kubernetes\.io/restartedAt}" 2>/dev/null)"
    ready="$(kubectl get deployment worker-pool -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    updated="$(kubectl get deployment worker-pool -n "'"$QUESTION_ID"'" -o jsonpath="{.status.updatedReplicas}" 2>/dev/null)"
    [ -n "$restarted" ] && [ "$ready" = "3" ] && [ "$updated" = "3" ]
  '

check_criterion "All live pods report FEATURE_FLAG=on (picked up the updated ConfigMap)" \
  bash -c '
    pods="$(kubectl get pods -n "'"$QUESTION_ID"'" -l app=worker-pool -o jsonpath="{.items[*].metadata.name}" 2>/dev/null)"
    [ -n "$pods" ] || exit 1
    for p in $pods; do
      val="$(kubectl exec "$p" -n "'"$QUESTION_ID"'" -- sh -c "echo \$FEATURE_FLAG" 2>/dev/null)"
      [ "$val" = "on" ] || exit 1
    done
  '

print_score
