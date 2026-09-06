#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-48-chained-native-sidecars-startup-order${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

POD="chained-sidecars-app"

# The Pod never reaches Running at all in the unsolved state (stuck at
# Init forever) - poll for the full chain: correct order, both native
# sidecars started, main container up.
STRUCT_OK=0
for _ in $(seq 1 30); do
  INIT_NAMES="$(kget pod "$POD" '{.spec.initContainers[*].name}' -n "$QUESTION_ID")"
  WARMER_STARTED="$(kget pod "$POD" '{.status.initContainerStatuses[?(@.name=="cache-warmer")].started}' -n "$QUESTION_ID")"
  BUILDER_STARTED="$(kget pod "$POD" '{.status.initContainerStatuses[?(@.name=="index-builder")].started}' -n "$QUESTION_ID")"
  WEB_READY="$(kget pod "$POD" '{.status.containerStatuses[?(@.name=="web")].ready}' -n "$QUESTION_ID")"
  PHASE="$(kget pod "$POD" '{.status.phase}' -n "$QUESTION_ID")"
  WEB_IMAGE="$(kget pod "$POD" '{.spec.containers[?(@.name=="web")].image}' -n "$QUESTION_ID")"

  if [ "$INIT_NAMES" = "cache-warmer index-builder" ] \
     && [ "$WARMER_STARTED" = "true" ] && [ "$BUILDER_STARTED" = "true" ] \
     && [ "$WEB_READY" = "true" ] && [ "$PHASE" = "Running" ] \
     && [ "$WEB_IMAGE" = "nginx:1.27-alpine" ]; then
    STRUCT_OK=1
    break
  fi
  sleep 5
done
check_criterion "initContainers reordered (cache-warmer before index-builder), both native sidecars started, 'web' ready, Pod 3/3 Running" \
  [ "$STRUCT_OK" = "1" ]

print_score
