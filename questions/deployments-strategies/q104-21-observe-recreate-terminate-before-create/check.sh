#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q104-21-observe-recreate-terminate-before-create${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Bundled into one criterion (not "exists" / "image" / "rollout finished" /
# "ready replicas" as separate checks) - setup.sh's own initial rollout
# already leaves batch-loader fully caught up on busybox:1.36, so any of
# those as an independent check would trivially pass before the candidate
# does anything. Gating everything on image==1.36.1 first makes this
# correctly score 0 pre-solve.
check_criterion "Deployment 'batch-loader' pod template is busybox:1.36.1 AND that rollout has finished (observedGeneration caught up, 3 updated/ready replicas)" \
  bash -c '
    [ "$(kubectl get deployment batch-loader -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)" = "busybox:1.36.1" ] || exit 1
    kubectl rollout status deployment/batch-loader -n "'"$QUESTION_ID"'" --timeout=30s >/dev/null 2>&1 || exit 1
    gen="$(kubectl get deployment batch-loader -n "'"$QUESTION_ID"'" -o jsonpath="{.metadata.generation}" 2>/dev/null)"
    observed="$(kubectl get deployment batch-loader -n "'"$QUESTION_ID"'" -o jsonpath="{.status.observedGeneration}" 2>/dev/null)"
    updated="$(kubectl get deployment batch-loader -n "'"$QUESTION_ID"'" -o jsonpath="{.status.updatedReplicas}" 2>/dev/null)"
    ready="$(kubectl get deployment batch-loader -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    [ -n "$gen" ] && [ "$gen" = "$observed" ] && [ "$updated" = "3" ] && [ "$ready" = "3" ]
  '

check_criterion "All running pods for app=batch-loader are on image busybox:1.36.1 (no old-image pods remain)" \
  bash -c '
    images="$(kubectl get pods -n "'"$QUESTION_ID"'" -l app=batch-loader \
      --field-selector=status.phase=Running \
      -o jsonpath="{range .items[*]}{.spec.containers[0].image}{\"\n\"}{end}" 2>/dev/null)"
    [ -n "$images" ] || exit 1
    count="$(echo "$images" | wc -l | tr -d " ")"
    [ "$count" = "3" ] || exit 1
    ! echo "$images" | grep -qv "^busybox:1.36.1$"
  '

print_score
