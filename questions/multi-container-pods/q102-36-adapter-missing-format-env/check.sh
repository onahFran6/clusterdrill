#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-36-adapter-missing-format-env${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

POD="format-adapter"

# Pod is already 2/2 Running in the unsolved state (adapter doesn't crash,
# it just does the wrong thing) - bundle the env-var fix with Running into
# ONE criterion so nothing scores until SOURCE_FORMAT actually lands.
STRUCT_OK=0
for _ in $(seq 1 24); do
  ENV_VAL="$(kget pod "$POD" '{.spec.containers[?(@.name=="adapter")].env[?(@.name=="SOURCE_FORMAT")].value}' -n "$QUESTION_ID")"
  PHASE="$(kget pod "$POD" '{.status.phase}' -n "$QUESTION_ID")"
  READY_FLAGS="$(kget pod "$POD" '{.status.containerStatuses[*].ready}' -n "$QUESTION_ID")"
  READY_COUNT="$(echo "$READY_FLAGS" | tr ' ' '\n' | grep -c '^true$' 2>/dev/null || true)"
  SOURCE_IMAGE="$(kget pod "$POD" '{.spec.containers[?(@.name=="source")].image}' -n "$QUESTION_ID")"
  ADAPTER_IMAGE="$(kget pod "$POD" '{.spec.containers[?(@.name=="adapter")].image}' -n "$QUESTION_ID")"

  if [ "$ENV_VAL" = "csv" ] && [ "$PHASE" = "Running" ] && [ "$READY_COUNT" = "2" ] \
     && [ "$SOURCE_IMAGE" = "busybox:1.36" ] && [ "$ADAPTER_IMAGE" = "busybox:1.36" ]; then
    STRUCT_OK=1
    break
  fi
  sleep 5
done
check_criterion "'adapter' has SOURCE_FORMAT=csv, Pod 2/2 Running, containers/images unchanged" \
  [ "$STRUCT_OK" = "1" ]

CONTENT_OK=0
for _ in $(seq 1 12); do
  ACTUAL="$(kubectl exec "$POD" -c adapter -n "$QUESTION_ID" -- cat /data/out.json 2>/dev/null)"
  if [ "$ACTUAL" = '{"name":"sensor-7","value":42.5}' ]; then
    CONTENT_OK=1
    break
  fi
  sleep 5
done
check_criterion "'adapter' container's /data/out.json contains the converted JSON, not the raw CSV passthrough" \
  [ "$CONTENT_OK" = "1" ]

print_score
