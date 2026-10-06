#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e` on purpose - see lib/grading.sh header comment.
set -uo pipefail

QUESTION_ID="q112-05-shared-memory-cache${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Shared volume is a 64Mi memory-backed emptyDir" \
  bash -c '
    medium="$(kubectl get pod cache-pair -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.volumes[0].emptyDir.medium}" 2>/dev/null)"
    size="$(kubectl get pod cache-pair -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.volumes[0].emptyDir.sizeLimit}" 2>/dev/null)"
    [ "$medium" = "Memory" ] && [ "$size" = "64Mi" ]
  '

check_criterion "Both containers mount the shared volume at /cache" \
  bash -c '
    vol="$(kubectl get pod cache-pair -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.volumes[0].name}" 2>/dev/null)"
    writer_path="$(kubectl get pod cache-pair -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[?(@.name==\"writer\")].volumeMounts[0].mountPath}" 2>/dev/null)"
    writer_vol="$(kubectl get pod cache-pair -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[?(@.name==\"writer\")].volumeMounts[0].name}" 2>/dev/null)"
    reader_path="$(kubectl get pod cache-pair -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[?(@.name==\"reader\")].volumeMounts[0].mountPath}" 2>/dev/null)"
    reader_vol="$(kubectl get pod cache-pair -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[?(@.name==\"reader\")].volumeMounts[0].name}" 2>/dev/null)"
    [ "$writer_path" = "/cache" ] && [ "$reader_path" = "/cache" ] && [ "$writer_vol" = "$vol" ] && [ "$reader_vol" = "$vol" ]
  '

check_criterion "Pod is Running (2/2)" \
  bash -c '
    phase="$(kubectl get pod cache-pair -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
    ready="$(kubectl get pod cache-pair -n "'"$QUESTION_ID"'" -o jsonpath="{.status.containerStatuses[*].ready}" 2>/dev/null)"
    [ "$phase" = "Running" ] && [ "$ready" = "true true" ]
  '

check_criterion "reader is actually seeing writer's output" \
  bash -c '
    for i in $(seq 1 10); do
      out="$(kubectl logs cache-pair -c reader -n "'"$QUESTION_ID"'" --tail=1 2>/dev/null)"
      [ -n "$out" ] && exit 0
      sleep 2
    done
    exit 1
  '

check_criterion "/cache is a tmpfs mount inside the container" \
  bash -c '
    kubectl exec cache-pair -c reader -n "'"$QUESTION_ID"'" -- sh -c "mount | grep \" /cache \"" 2>/dev/null | grep -q tmpfs
  '

print_score
