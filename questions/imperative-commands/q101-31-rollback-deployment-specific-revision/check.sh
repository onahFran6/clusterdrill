#!/usr/bin/env bash
# Grades ONLY live cluster state - never a client-supplied "done" flag.
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q101-31-rollback-deployment-specific-revision${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# rollout history --revision=N only shows the pod template, not live status,
# so it can't prove a revision was actually healthy on its own - what proves
# it is the Deployment's live pods actually running that exact image at
# 2/2 ready right now. Bundled into one criterion: at setup.sh's unsolved
# state the image is already the wrong (broken, revision-4) one, so this is
# false until the candidate rolls back to the correct revision.
check_criterion "Deployment 'orders-api' is back on nginx:1.23-alpine (the last healthy revision) with 2/2 replicas ready and updated" \
  bash -c '
    image="$(kubectl get deployment orders-api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    [ "$image" = "nginx:1.23-alpine" ] || exit 1
    kubectl rollout status deployment/orders-api -n "'"$QUESTION_ID"'" --timeout=30s >/dev/null 2>&1 || exit 1
    ready="$(kubectl get deployment orders-api -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    updated="$(kubectl get deployment orders-api -n "'"$QUESTION_ID"'" -o jsonpath="{.status.updatedReplicas}" 2>/dev/null)"
    [ "$ready" = "2" ] && [ "$updated" = "2" ]
  '

# Confirms the candidate actually used a rollback (which records a fresh
# revision pointing at the old ReplicaSet) rather than hand-patching the
# image string to the right value - the live ReplicaSet now serving traffic
# must carry a revision number past the 4 setup.sh recorded.
check_criterion "Live ReplicaSet's revision annotation advanced past revision 4 (a real rollback happened)" \
  bash -c '
    rev="$(kubectl get rs -n "'"$QUESTION_ID"'" -l app=orders-api \
      -o jsonpath="{.items[?(@.spec.replicas>0)].metadata.annotations.deployment\.kubernetes\.io/revision}" 2>/dev/null)"
    [ -n "$rev" ] && [ "$rev" -ge 5 ]
  '

print_score
