#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q114-12-two-apps-one-claim${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

mount_ok() {
  local deploy="$1" want_subpath="$2"
  local vol mountpath subpath claim
  claim="$(kubectl get deployment "$deploy" -n "$QUESTION_ID" \
    -o jsonpath='{.spec.template.spec.volumes[0].persistentVolumeClaim.claimName}' 2>/dev/null)"
  [ "$claim" = "shared" ] || return 1
  vol="$(kubectl get deployment "$deploy" -n "$QUESTION_ID" \
    -o jsonpath='{.spec.template.spec.volumes[0].name}' 2>/dev/null)"
  mountpath="$(kubectl get deployment "$deploy" -n "$QUESTION_ID" \
    -o jsonpath="{.spec.template.spec.containers[0].volumeMounts[?(@.name==\"$vol\")].mountPath}" 2>/dev/null)"
  subpath="$(kubectl get deployment "$deploy" -n "$QUESTION_ID" \
    -o jsonpath="{.spec.template.spec.containers[0].volumeMounts[?(@.name==\"$vol\")].subPath}" 2>/dev/null)"
  [ "$mountpath" = "/data" ] && [ "$subpath" = "$want_subpath" ]
}

check_criterion "Deployment api mounts the shared claim at /data via subPath=api" \
  mount_ok api api

check_criterion "Deployment worker mounts the shared claim at /data via subPath=worker" \
  mount_ok worker worker

check_criterion "Both Deployments are Running" \
  bash -c '
    a="$(kubectl get deployment api -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    w="$(kubectl get deployment worker -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    [ "$a" = "1" ] && [ "$w" = "1" ]
  '

check_criterion "api's /data/owner says api, worker's /data/owner says worker" \
  bash -c '
    a="$(kubectl exec deploy/api -n "'"$QUESTION_ID"'" -- cat /data/owner 2>/dev/null)"
    w="$(kubectl exec deploy/worker -n "'"$QUESTION_ID"'" -- cat /data/owner 2>/dev/null)"
    [ "$a" = "api" ] && [ "$w" = "worker" ]
  '

check_criterion "Both api/ and worker/ folders exist side by side at the claim's root" \
  bash -c '
    out="$(kubectl run q114-12-inspect -n "'"$QUESTION_ID"'" --image=busybox:1.36 --restart=Never --rm -i \
      --overrides="{\"spec\":{\"volumes\":[{\"name\":\"s\",\"persistentVolumeClaim\":{\"claimName\":\"shared\"}}],\"containers\":[{\"name\":\"i\",\"image\":\"busybox:1.36\",\"command\":[\"ls\",\"/all\"],\"volumeMounts\":[{\"name\":\"s\",\"mountPath\":\"/all\"}]}]}}" \
      -- true 2>/dev/null)"
    echo "$out" | grep -q "api" && echo "$out" | grep -q "worker"
  '

print_score
