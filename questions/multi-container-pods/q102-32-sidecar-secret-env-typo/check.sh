#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-32-sidecar-secret-env-typo${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

POD="token-reporter"

# In the unsolved state "app" is already Running (it was never broken), so
# Running-ness alone can't be its own criterion (false positive). Bundle the
# structural fix (secretRef.name corrected) with the Pod reaching 2/2
# Running into ONE criterion - nothing scores until reporter actually starts.
STRUCT_OK=0
for _ in $(seq 1 24); do
  SECRET_NAME="$(kget pod "$POD" '{.spec.containers[?(@.name=="reporter")].envFrom[0].secretRef.name}' -n "$QUESTION_ID")"
  PHASE="$(kget pod "$POD" '{.status.phase}' -n "$QUESTION_ID")"
  READY_FLAGS="$(kget pod "$POD" '{.status.containerStatuses[*].ready}' -n "$QUESTION_ID")"
  READY_COUNT="$(echo "$READY_FLAGS" | tr ' ' '\n' | grep -c '^true$' 2>/dev/null || true)"
  APP_IMAGE="$(kget pod "$POD" '{.spec.containers[?(@.name=="app")].image}' -n "$QUESTION_ID")"
  REPORTER_IMAGE="$(kget pod "$POD" '{.spec.containers[?(@.name=="reporter")].image}' -n "$QUESTION_ID")"

  if [ "$SECRET_NAME" = "api-credentials" ] && [ "$PHASE" = "Running" ] \
     && [ "$READY_COUNT" = "2" ] \
     && [ "$APP_IMAGE" = "busybox:1.36" ] && [ "$REPORTER_IMAGE" = "busybox:1.36" ]; then
    STRUCT_OK=1
    break
  fi
  sleep 5
done
check_criterion "Pod 'token-reporter' 2/2 Running, 'reporter' envFrom[0].secretRef.name corrected to 'api-credentials', containers/images unchanged" \
  [ "$STRUCT_OK" = "1" ]

# The real proof reporter actually loaded the Secret's real value.
CONTENT_OK=0
for _ in $(seq 1 12); do
  ACTUAL="$(kubectl exec "$POD" -c reporter -n "$QUESTION_ID" -- cat /report/status.txt 2>/dev/null)"
  if [ "$ACTUAL" = "sample-reporter-token" ]; then
    CONTENT_OK=1
    break
  fi
  sleep 5
done
check_criterion "'reporter' container's /report/status.txt contains the real Secret value 'sample-reporter-token' (not 'MISSING_TOKEN')" \
  [ "$CONTENT_OK" = "1" ]

print_score
