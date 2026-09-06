#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q109-47-generic-ephemeral-volume-storageclass-override${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'benchmark-runner' declares a generic ephemeral volume 'scratch' requesting 256Mi ReadWriteOnce via fast-scratch" \
  bash -c "[ \"\$(kubectl get pod benchmark-runner -n '$QUESTION_ID' -o jsonpath='{.spec.volumes[?(@.name==\"scratch\")].ephemeral.volumeClaimTemplate.spec.resources.requests.storage}')\" = '256Mi' ] && \
    [ \"\$(kubectl get pod benchmark-runner -n '$QUESTION_ID' -o jsonpath='{.spec.volumes[?(@.name==\"scratch\")].ephemeral.volumeClaimTemplate.spec.accessModes[0]}')\" = 'ReadWriteOnce' ] && \
    [ \"\$(kubectl get pod benchmark-runner -n '$QUESTION_ID' -o jsonpath='{.spec.volumes[?(@.name==\"scratch\")].ephemeral.volumeClaimTemplate.spec.storageClassName}')\" = 'fast-scratch' ]"

check_criterion "Volume mounted at /scratch" \
  [ "$(kget pod benchmark-runner '{.spec.containers[0].volumeMounts[0].mountPath}' -n "$QUESTION_ID")" = "/scratch" ]

check_criterion "Auto-created PVC 'benchmark-runner-scratch' is Bound via StorageClass 'fast-scratch'" \
  bash -c '
    for _ in $(seq 1 15); do
      phase="$(kubectl get pvc benchmark-runner-scratch -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
      sc="$(kubectl get pvc benchmark-runner-scratch -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.storageClassName}" 2>/dev/null)"
      [ "$phase" = "Bound" ] && [ "$sc" = "fast-scratch" ] && exit 0
      sleep 2
    done
    exit 1
  '

check_criterion "Pod 'benchmark-runner' is Running" \
  bash -c "[ \"\$(kubectl get pod benchmark-runner -n '$QUESTION_ID' -o jsonpath='{.status.phase}' 2>/dev/null)\" = 'Running' ]"

print_score
