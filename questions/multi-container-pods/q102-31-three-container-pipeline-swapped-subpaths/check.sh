#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-31-three-container-pipeline-swapped-subpaths${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

POD="pipeline-stages"

# The seeded pod is already Running 3/3 in the unsolved state (nothing
# crashes) and its container identity/images never change either, so none
# of that can be its own criterion (would be a false positive per the
# no-false-positives rule). Bundle ALL of it into the SAME criterion as the
# actual fix - every volumeMounts[].subPath corrected - so nothing scores
# until the real bug is gone. Poll for a stable snapshot rather than a
# single read, since a just-recreated pod takes a moment past apply to
# reach Running.
STRUCT_OK=0
for _ in $(seq 1 24); do
  PHASE="$(kget pod "$POD" '{.status.phase}' -n "$QUESTION_ID")"
  READY_FLAGS="$(kget pod "$POD" '{.status.containerStatuses[*].ready}' -n "$QUESTION_ID")"
  READY_COUNT="$(echo "$READY_FLAGS" | tr ' ' '\n' | grep -c '^true$' 2>/dev/null || true)"
  CONTAINER_NAMES="$(kget pod "$POD" '{.spec.containers[*].name}' -n "$QUESTION_ID")"
  PRODUCER_IMAGE="$(kget pod "$POD" '{.spec.containers[?(@.name=="producer")].image}' -n "$QUESTION_ID")"
  TRANSFORMER_IMAGE="$(kget pod "$POD" '{.spec.containers[?(@.name=="transformer")].image}' -n "$QUESTION_ID")"
  CONSUMER_IMAGE="$(kget pod "$POD" '{.spec.containers[?(@.name=="consumer")].image}' -n "$QUESTION_ID")"
  PRODUCER_SUBPATH="$(kget pod "$POD" '{.spec.containers[?(@.name=="producer")].volumeMounts[?(@.mountPath=="/data")].subPath}' -n "$QUESTION_ID")"
  TRANSFORMER_IN_SUBPATH="$(kget pod "$POD" '{.spec.containers[?(@.name=="transformer")].volumeMounts[?(@.mountPath=="/in")].subPath}' -n "$QUESTION_ID")"
  TRANSFORMER_OUT_SUBPATH="$(kget pod "$POD" '{.spec.containers[?(@.name=="transformer")].volumeMounts[?(@.mountPath=="/out")].subPath}' -n "$QUESTION_ID")"
  CONSUMER_SUBPATH="$(kget pod "$POD" '{.spec.containers[?(@.name=="consumer")].volumeMounts[?(@.mountPath=="/final")].subPath}' -n "$QUESTION_ID")"

  if [ "$PHASE" = "Running" ] && [ "$READY_COUNT" = "3" ] \
     && [ "$CONTAINER_NAMES" = "producer transformer consumer" ] \
     && [ "$PRODUCER_IMAGE" = "busybox:1.36" ] \
     && [ "$TRANSFORMER_IMAGE" = "busybox:1.36" ] \
     && [ "$CONSUMER_IMAGE" = "busybox:1.36" ] \
     && [ "$PRODUCER_SUBPATH" = "stage1" ] \
     && [ "$TRANSFORMER_IN_SUBPATH" = "stage1" ] \
     && [ "$TRANSFORMER_OUT_SUBPATH" = "stage2" ] \
     && [ "$CONSUMER_SUBPATH" = "stage2" ]; then
    STRUCT_OK=1
    break
  fi
  sleep 5
done
check_criterion "Pod 'pipeline-stages' Running 3/3, containers/images unchanged, every volumeMounts[].subPath corrected (producer:/data=stage1, transformer:/in=stage1, transformer:/out=stage2, consumer:/final=stage2)" \
  [ "$STRUCT_OK" = "1" ]

# The real proof the pipeline flows correctly end to end: 'transformer'
# actually noticed 'producer's file and processed it, and 'consumer' reads
# the transformed result - not producer's raw payload, and not nothing.
# Poll (rather than a single exec) since transformer needs a few seconds
# after the pod starts to notice the input file and write its output.
CONTENT_OK=0
for _ in $(seq 1 24); do
  ACTUAL="$(kubectl exec "$POD" -c consumer -n "$QUESTION_ID" -- cat /final/payload.txt 2>/dev/null)"
  if [ "$ACTUAL" = "TRANSFORMED:batch-payload-4471" ]; then
    CONTENT_OK=1
    break
  fi
  sleep 5
done
check_criterion "'consumer' container's /final/payload.txt exactly equals 'TRANSFORMED:batch-payload-4471' (producer's original payload, transformed once by 'transformer')" \
  [ "$CONTENT_OK" = "1" ]

print_score
