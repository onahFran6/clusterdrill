#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q109-48-multi-pvc-different-storageclasses-one-pod${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "PVC 'cache-claim' requests 100Mi via fast-tier" \
  bash -c "[ \"\$(kubectl get pvc cache-claim -n '$QUESTION_ID' -o jsonpath='{.spec.resources.requests.storage}' 2>/dev/null)\" = '100Mi' ] && \
    [ \"\$(kubectl get pvc cache-claim -n '$QUESTION_ID' -o jsonpath='{.spec.storageClassName}' 2>/dev/null)\" = 'fast-tier' ]"

check_criterion "PVC 'records-claim' requests 200Mi via durable-tier" \
  bash -c "[ \"\$(kubectl get pvc records-claim -n '$QUESTION_ID' -o jsonpath='{.spec.resources.requests.storage}' 2>/dev/null)\" = '200Mi' ] && \
    [ \"\$(kubectl get pvc records-claim -n '$QUESTION_ID' -o jsonpath='{.spec.storageClassName}' 2>/dev/null)\" = 'durable-tier' ]"

check_criterion "Both PVCs are Bound" \
  bash -c '
    for _ in $(seq 1 15); do
      p1="$(kubectl get pvc cache-claim -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
      p2="$(kubectl get pvc records-claim -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
      [ "$p1" = "Bound" ] && [ "$p2" = "Bound" ] && exit 0
      sleep 2
    done
    exit 1
  '

check_criterion "Pod 'data-processor' mounts cache-claim at /cache and records-claim at /records" \
  bash -c '
    vol1="$(kubectl get pod data-processor -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.volumes[?(@.persistentVolumeClaim.claimName==\"cache-claim\")].name}" 2>/dev/null)"
    vol2="$(kubectl get pod data-processor -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.volumes[?(@.persistentVolumeClaim.claimName==\"records-claim\")].name}" 2>/dev/null)"
    [ -n "$vol1" ] && [ -n "$vol2" ] || exit 1
    mp1="$(kubectl get pod data-processor -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].volumeMounts[?(@.name==\"$vol1\")].mountPath}" 2>/dev/null)"
    mp2="$(kubectl get pod data-processor -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].volumeMounts[?(@.name==\"$vol2\")].mountPath}" 2>/dev/null)"
    [ "$mp1" = "/cache" ] && [ "$mp2" = "/records" ]
  '

check_criterion "Pod 'data-processor' is Running" \
  bash -c "[ \"\$(kubectl get pod data-processor -n '$QUESTION_ID' -o jsonpath='{.status.phase}' 2>/dev/null)\" = 'Running' ]"

print_score
