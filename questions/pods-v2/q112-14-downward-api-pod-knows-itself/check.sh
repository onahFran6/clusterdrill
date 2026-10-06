#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e` on purpose - see lib/grading.sh header comment.
set -uo pipefail

QUESTION_ID="q112-14-downward-api-pod-knows-itself${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Labels app=meta,version=v3, annotation build=4521, memory limit 64Mi" \
  bash -c '
    app="$(kubectl get pod meta -n "'"$QUESTION_ID"'" -o jsonpath="{.metadata.labels.app}" 2>/dev/null)"
    version="$(kubectl get pod meta -n "'"$QUESTION_ID"'" -o jsonpath="{.metadata.labels.version}" 2>/dev/null)"
    build="$(kubectl get pod meta -n "'"$QUESTION_ID"'" -o jsonpath="{.metadata.annotations.build}" 2>/dev/null)"
    memlimit="$(kubectl get pod meta -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].resources.limits.memory}" 2>/dev/null)"
    [ "$app" = "meta" ] && [ "$version" = "v3" ] && [ "$build" = "4521" ] && [ "$memlimit" = "64Mi" ]
  '

check_criterion "POD_IP comes from status.podIP via fieldRef" \
  bash -c '
    path="$(kubectl get pod meta -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].env[?(@.name==\"POD_IP\")].valueFrom.fieldRef.fieldPath}" 2>/dev/null)"
    [ "$path" = "status.podIP" ]
  '

check_criterion "MEM_LIMIT_MI comes from the agent container's own limits.memory, divisor 1Mi" \
  bash -c '
    cname="$(kubectl get pod meta -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].env[?(@.name==\"MEM_LIMIT_MI\")].valueFrom.resourceFieldRef.containerName}" 2>/dev/null)"
    resource="$(kubectl get pod meta -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].env[?(@.name==\"MEM_LIMIT_MI\")].valueFrom.resourceFieldRef.resource}" 2>/dev/null)"
    divisor="$(kubectl get pod meta -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].env[?(@.name==\"MEM_LIMIT_MI\")].valueFrom.resourceFieldRef.divisor}" 2>/dev/null)"
    [ "$cname" = "agent" ] && [ "$resource" = "limits.memory" ] && [ "$divisor" = "1Mi" ]
  '

check_criterion "downwardAPI volume exposes labels and annotations at paths labels/annotations" \
  bash -c '
    items="$(kubectl get pod meta -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.volumes[0].downwardAPI.items}" 2>/dev/null)"
    count="$(echo "$items" | jq "length" 2>/dev/null)"
    labels_ok="$(echo "$items" | jq -e "[.[] | select(.path==\"labels\" and .fieldRef.fieldPath==\"metadata.labels\")] | length == 1" 2>/dev/null)"
    annotations_ok="$(echo "$items" | jq -e "[.[] | select(.path==\"annotations\" and .fieldRef.fieldPath==\"metadata.annotations\")] | length == 1" 2>/dev/null)"
    [ "$count" = "2" ] && [ "$labels_ok" = "true" ] && [ "$annotations_ok" = "true" ]
  '

check_criterion "Pod is Running" \
  bash -c '[ "$(kubectl get pod meta -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)" = "Running" ]'

check_criterion "MEM_LIMIT_MI reads 64 and the labels file shows app=\"meta\"" \
  bash -c '
    mem="$(kubectl exec meta -n "'"$QUESTION_ID"'" -- printenv MEM_LIMIT_MI 2>/dev/null)"
    labels="$(kubectl exec meta -n "'"$QUESTION_ID"'" -- cat /etc/podinfo/labels 2>/dev/null)"
    [ "$mem" = "64" ] && echo "$labels" | grep -q "app=\"meta\""
  '

print_score
