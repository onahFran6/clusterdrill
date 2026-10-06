#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q114-14-a-claim-for-every-replica${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Service kv is headless and selects the StatefulSet's pods" \
  bash -c '
    cip="$(kubectl get svc kv -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.clusterIP}" 2>/dev/null)"
    sel_key="$(kubectl get svc kv -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.selector.app}" 2>/dev/null)"
    sts_key="$(kubectl get statefulset kv -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.selector.matchLabels.app}" 2>/dev/null)"
    [ "$cip" = "None" ] && [ -n "$sel_key" ] && [ "$sel_key" = "$sts_key" ]
  '

check_criterion "StatefulSet kv has exactly one volumeClaimTemplates entry 'data' for 100Mi" \
  bash -c '
    name="$(kubectl get statefulset kv -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.volumeClaimTemplates[0].metadata.name}" 2>/dev/null)"
    size="$(kubectl get statefulset kv -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.volumeClaimTemplates[0].spec.resources.requests.storage}" 2>/dev/null)"
    second="$(kubectl get statefulset kv -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.volumeClaimTemplates[1]}" 2>/dev/null)"
    [ "$name" = "data" ] && [ "$size" = "100Mi" ] && [ -z "$second" ]
  '

check_criterion "StatefulSet kv is scaled to 1 replica" \
  bash -c '[ "$(kubectl get statefulset kv -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.replicas}" 2>/dev/null)" = "1" ]'

check_criterion "kv-0's /data/id still reads kv-0 (same identity survived the delete+recreate)" \
  bash -c '
    for i in $(seq 1 12); do
      val="$(kubectl exec kv-0 -n "'"$QUESTION_ID"'" -- cat /data/id 2>/dev/null)"
      [ "$val" = "kv-0" ] && exit 0
      sleep 5
    done
    exit 1
  '

check_criterion "Both data-kv-0 and data-kv-1 PVCs still exist after scaling down" \
  bash -c '
    kubectl get pvc data-kv-0 -n "'"$QUESTION_ID"'" >/dev/null 2>&1 && \
    kubectl get pvc data-kv-1 -n "'"$QUESTION_ID"'" >/dev/null 2>&1
  '

print_score
