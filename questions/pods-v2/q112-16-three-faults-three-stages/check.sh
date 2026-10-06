#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e` on purpose - see lib/grading.sh header comment.
set -uo pipefail

QUESTION_ID="q112-16-three-faults-three-stages${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "PVC report-data exists: 100Mi, ReadWriteOnce" \
  bash -c '
    size="$(kubectl get pvc report-data -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.resources.requests.storage}" 2>/dev/null)"
    mode="$(kubectl get pvc report-data -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.accessModes[0]}" 2>/dev/null)"
    [ "$size" = "100Mi" ] && [ "$mode" = "ReadWriteOnce" ]
  '

check_criterion "report's image tag is fixed to busybox:1.36" \
  bash -c '[ "$(kubectl get pod report -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].image}" 2>/dev/null)" = "busybox:1.36" ]'

check_criterion "API_KEY's secretKeyRef key is fixed to api-key" \
  bash -c '
    name="$(kubectl get pod report -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].env[?(@.name==\"API_KEY\")].valueFrom.secretKeyRef.name}" 2>/dev/null)"
    key="$(kubectl get pod report -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].env[?(@.name==\"API_KEY\")].valueFrom.secretKeyRef.key}" 2>/dev/null)"
    [ "$name" = "report-secret" ] && [ "$key" = "api-key" ]
  '

check_criterion "Pod 'report' is Running, 1/1" \
  bash -c '
    for i in $(seq 1 15); do
      phase="$(kubectl get pod report -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
      ready="$(kubectl get pod report -n "'"$QUESTION_ID"'" -o jsonpath="{.status.containerStatuses[0].ready}" 2>/dev/null)"
      [ "$phase" = "Running" ] && [ "$ready" = "true" ] && exit 0
      sleep 2
    done
    exit 1
  '

print_score
