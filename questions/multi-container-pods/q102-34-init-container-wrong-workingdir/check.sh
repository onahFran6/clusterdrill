#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-34-init-container-wrong-workingdir${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

POD="handoff-app"

# Pod is already 2/2 Running in the unsolved state (nothing crashes), so
# bundle the structural fix (workingDir corrected) into the SAME criterion
# as Running - nothing scores until the real fix lands.
STRUCT_OK=0
for _ in $(seq 1 24); do
  WORKDIR="$(kget pod "$POD" '{.spec.initContainers[?(@.name=="stager")].workingDir}' -n "$QUESTION_ID")"
  PHASE="$(kget pod "$POD" '{.status.phase}' -n "$QUESTION_ID")"
  READY_FLAGS="$(kget pod "$POD" '{.status.containerStatuses[*].ready}' -n "$QUESTION_ID")"
  READY_COUNT="$(echo "$READY_FLAGS" | tr ' ' '\n' | grep -c '^true$' 2>/dev/null || true)"
  INIT_IMAGE="$(kget pod "$POD" '{.spec.initContainers[?(@.name=="stager")].image}' -n "$QUESTION_ID")"
  MAIN_IMAGE="$(kget pod "$POD" '{.spec.containers[?(@.name=="consumer")].image}' -n "$QUESTION_ID")"

  if [ "$WORKDIR" = "/stage" ] && [ "$PHASE" = "Running" ] && [ "$READY_COUNT" = "1" ] \
     && [ "$INIT_IMAGE" = "busybox:1.36" ] && [ "$MAIN_IMAGE" = "busybox:1.36" ]; then
    STRUCT_OK=1
    break
  fi
  sleep 5
done
check_criterion "init container 'stager' workingDir corrected to /stage, Pod 2/2 Running, containers/images unchanged" \
  [ "$STRUCT_OK" = "1" ]

CONTENT_OK=0
for _ in $(seq 1 6); do
  ACTUAL="$(kubectl exec "$POD" -c consumer -n "$QUESTION_ID" -- cat /consume/handoff.txt 2>/dev/null)"
  if [ "$ACTUAL" = "shipment-ready-778" ]; then
    CONTENT_OK=1
    break
  fi
  sleep 3
done
check_criterion "'consumer' container's /consume/handoff.txt contains exactly 'shipment-ready-778'" \
  [ "$CONTENT_OK" = "1" ]

print_score
