#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-46-ambassador-dependent-env-var-order${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

POD="ambassador-target"

# Pod is already 2/2 Running in the unsolved state (ambassador doesn't
# crash, it just writes the unexpanded literal) - bundle the structural
# check (env names/values unchanged, just reordered) with Running.
STRUCT_OK=0
for _ in $(seq 1 24); do
  ENV_NAMES="$(kget pod "$POD" '{.spec.containers[?(@.name=="ambassador")].env[*].name}' -n "$QUESTION_ID")"
  HOST_VAL="$(kget pod "$POD" '{.spec.containers[?(@.name=="ambassador")].env[?(@.name=="BACKEND_HOST")].value}' -n "$QUESTION_ID")"
  PORT_VAL="$(kget pod "$POD" '{.spec.containers[?(@.name=="ambassador")].env[?(@.name=="BACKEND_PORT")].value}' -n "$QUESTION_ID")"
  TARGET_VAL="$(kget pod "$POD" '{.spec.containers[?(@.name=="ambassador")].env[?(@.name=="TARGET_ADDR")].value}' -n "$QUESTION_ID")"
  PHASE="$(kget pod "$POD" '{.status.phase}' -n "$QUESTION_ID")"
  READY_FLAGS="$(kget pod "$POD" '{.status.containerStatuses[*].ready}' -n "$QUESTION_ID")"
  READY_COUNT="$(echo "$READY_FLAGS" | tr ' ' '\n' | grep -c '^true$' 2>/dev/null || true)"

  if [ "$ENV_NAMES" = "BACKEND_HOST BACKEND_PORT TARGET_ADDR" ] \
     && [ "$HOST_VAL" = "primary-api" ] && [ "$PORT_VAL" = "9090" ] \
     && [ "$TARGET_VAL" = '$(BACKEND_HOST):$(BACKEND_PORT)' ] \
     && [ "$PHASE" = "Running" ] && [ "$READY_COUNT" = "2" ]; then
    STRUCT_OK=1
    break
  fi
  sleep 4
done
check_criterion "'ambassador' env reordered (BACKEND_HOST, BACKEND_PORT before TARGET_ADDR), names/values unchanged, Pod 2/2 Running" \
  [ "$STRUCT_OK" = "1" ]

CONTENT_OK=0
for _ in $(seq 1 12); do
  ACTUAL="$(kubectl exec "$POD" -c ambassador -n "$QUESTION_ID" -- cat /report/target.txt 2>/dev/null)"
  if [ "$ACTUAL" = "primary-api:9090" ]; then
    CONTENT_OK=1
    break
  fi
  sleep 3
done
check_criterion "'ambassador' container's /report/target.txt contains the fully-expanded 'primary-api:9090', not the literal placeholder" \
  [ "$CONTENT_OK" = "1" ]

print_score
