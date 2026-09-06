#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-43-resourcefieldref-memory-divisor${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

POD="sized-worker"

# Pod is already 2/2 Running in the unsolved state (worker doesn't crash,
# it just computes the wrong number) - bundle the structural fix with
# Running into ONE criterion.
STRUCT_OK=0
for _ in $(seq 1 24); do
  DIVISOR="$(kget pod "$POD" '{.spec.containers[?(@.name=="worker")].env[?(@.name=="MEM_LIMIT_MB")].valueFrom.resourceFieldRef.divisor}' -n "$QUESTION_ID")"
  RESOURCE="$(kget pod "$POD" '{.spec.containers[?(@.name=="worker")].env[?(@.name=="MEM_LIMIT_MB")].valueFrom.resourceFieldRef.resource}' -n "$QUESTION_ID")"
  MEM_LIMIT="$(kget pod "$POD" '{.spec.containers[?(@.name=="worker")].resources.limits.memory}' -n "$QUESTION_ID")"
  PHASE="$(kget pod "$POD" '{.status.phase}' -n "$QUESTION_ID")"
  READY_FLAGS="$(kget pod "$POD" '{.status.containerStatuses[*].ready}' -n "$QUESTION_ID")"
  READY_COUNT="$(echo "$READY_FLAGS" | tr ' ' '\n' | grep -c '^true$' 2>/dev/null || true)"

  if [ "$DIVISOR" = "1Mi" ] && [ "$RESOURCE" = "limits.memory" ] && [ "$MEM_LIMIT" = "64Mi" ] \
     && [ "$PHASE" = "Running" ] && [ "$READY_COUNT" = "2" ]; then
    STRUCT_OK=1
    break
  fi
  sleep 4
done
check_criterion "'worker' resourceFieldRef.divisor corrected to 1Mi (resource/limit unchanged), Pod 2/2 Running" \
  [ "$STRUCT_OK" = "1" ]

CONTENT_OK=0
for _ in $(seq 1 12); do
  ACTUAL="$(kubectl exec "$POD" -c worker -n "$QUESTION_ID" -- cat /data/mem_limit_mb.txt 2>/dev/null)"
  if [ "$ACTUAL" = "64" ]; then
    CONTENT_OK=1
    break
  fi
  sleep 3
done
check_criterion "'worker' container's /data/mem_limit_mb.txt contains exactly '64' (mebibytes, not raw bytes)" \
  [ "$CONTENT_OK" = "1" ]

print_score
