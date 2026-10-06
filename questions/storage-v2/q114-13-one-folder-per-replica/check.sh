#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q114-13-one-folder-per-replica${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Bundled on purpose: "3 replicas Running" is already true in the unsolved
# broken state (they're all colliding on the same file, but still
# Running) - only the combination with the real subPathExpr/env fix proves
# anything changed.
check_criterion "POD_NAME env from Downward API + subPathExpr=\$(POD_NAME), command unchanged" \
  bash -c '
    env_path="$(kubectl get deployment logger -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].env[?(@.name==\"POD_NAME\")].valueFrom.fieldRef.fieldPath}" 2>/dev/null)"
    subpathexpr="$(kubectl get deployment logger -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].volumeMounts[0].subPathExpr}" 2>/dev/null)"
    cmd="$(kubectl get deployment logger -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].command}" 2>/dev/null)"
    [ "$env_path" = "metadata.name" ] && [ "$subpathexpr" = "\$(POD_NAME)" ] \
      && echo "$cmd" | grep -q "app.log"
  '

check_criterion "Each of the 3 current (stable) pod folders exists side by side at the claim's root" \
  bash -c '
    for i in $(seq 1 10); do
      # Only trust a snapshot where exactly 3 pods are Running and stable -
      # a rollout in progress can leave an old pod still Terminating and a
      # new one still ContainerCreating for a few seconds after
      # `kubectl rollout status` itself already reports done.
      pod_count="$(kubectl get pods -n "'"$QUESTION_ID"'" -l app=logger --no-headers 2>/dev/null | grep -c Running)"
      pods="$(kubectl get pods -n "'"$QUESTION_ID"'" -l app=logger -o jsonpath="{.items[*].metadata.name}" 2>/dev/null)"
      if [ "$pod_count" = "3" ]; then
        out="$(kubectl run q114-13-look -n "'"$QUESTION_ID"'" --image=busybox:1.36 --restart=Never --rm -i \
          --overrides="{\"spec\":{\"volumes\":[{\"name\":\"l\",\"persistentVolumeClaim\":{\"claimName\":\"logs\"}}],\"containers\":[{\"name\":\"i\",\"image\":\"busybox:1.36\",\"command\":[\"ls\",\"/all\"],\"volumeMounts\":[{\"name\":\"l\",\"mountPath\":\"/all\"}]}]}}" \
          -- true 2>/dev/null)"
        ok=1
        for p in $pods; do
          echo "$out" | grep -q "^$p\$" || ok=0
        done
        [ "$ok" = "1" ] && exit 0
      fi
      sleep 5
    done
    exit 1
  '

print_score
