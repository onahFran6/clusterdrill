#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e` on purpose - see lib/grading.sh header comment.
set -uo pipefail

QUESTION_ID="q112-07-storageclass-waitforfirstconsumer${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "PVC logs-pvc requests 200Mi ReadWriteOnce via the cluster's default storage class" \
  bash -c '
    size="$(kubectl get pvc logs-pvc -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.resources.requests.storage}" 2>/dev/null)"
    mode="$(kubectl get pvc logs-pvc -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.accessModes[0]}" 2>/dev/null)"
    sc="$(kubectl get pvc logs-pvc -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.storageClassName}" 2>/dev/null)"
    default_sc="$(kubectl get sc -o jsonpath="{range .items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class==\"true\")]}{.metadata.name}{end}")"
    [ "$size" = "200Mi" ] && [ "$mode" = "ReadWriteOnce" ] && [ -n "$default_sc" ] && [ "$sc" = "$default_sc" ]
  '

check_criterion "Pod 'logger' exists, mounts logs-pvc at /logs, image busybox:1.36" \
  bash -c '
    image="$(kubectl get pod logger -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].image}" 2>/dev/null)"
    claim="$(kubectl get pod logger -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.volumes[0].persistentVolumeClaim.claimName}" 2>/dev/null)"
    mountpath="$(kubectl get pod logger -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].volumeMounts[0].mountPath}" 2>/dev/null)"
    [ "$image" = "busybox:1.36" ] && [ "$claim" = "logs-pvc" ] && [ "$mountpath" = "/logs" ]
  '

check_criterion "Pod 'logger' is Running" \
  bash -c '
    for i in $(seq 1 15); do
      [ "$(kubectl get pod logger -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)" = "Running" ] && exit 0
      sleep 2
    done
    exit 1
  '

check_criterion "PVC logs-pvc reaches Bound once the Pod exists" \
  bash -c '
    for i in $(seq 1 10); do
      phase="$(kubectl get pvc logs-pvc -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
      [ "$phase" = "Bound" ] && exit 0
      sleep 2
    done
    exit 1
  '

print_score
