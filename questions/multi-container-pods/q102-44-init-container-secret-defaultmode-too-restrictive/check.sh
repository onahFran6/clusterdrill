#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-44-init-container-secret-defaultmode-too-restrictive${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

POD="cert-staging-app"

# Pod is already 1/1 Running in the unsolved state (cert-loader's failed cp
# is silently swallowed, nothing crashes) - bundle the structural fix
# (defaultMode corrected, runAsUser preserved) with Running into ONE
# criterion. 0444 octal is stored/read back as decimal 292.
STRUCT_OK=0
for _ in $(seq 1 24); do
  DEFAULT_MODE="$(kget pod "$POD" '{.spec.volumes[?(@.name=="cert")].secret.defaultMode}' -n "$QUESTION_ID")"
  RUN_AS_USER="$(kget pod "$POD" '{.spec.initContainers[?(@.name=="cert-loader")].securityContext.runAsUser}' -n "$QUESTION_ID")"
  PHASE="$(kget pod "$POD" '{.status.phase}' -n "$QUESTION_ID")"
  READY_FLAGS="$(kget pod "$POD" '{.status.containerStatuses[*].ready}' -n "$QUESTION_ID")"
  READY_COUNT="$(echo "$READY_FLAGS" | tr ' ' '\n' | grep -c '^true$' 2>/dev/null || true)"

  if [ "$DEFAULT_MODE" = "292" ] && [ "$RUN_AS_USER" = "1000" ] \
     && [ "$PHASE" = "Running" ] && [ "$READY_COUNT" = "1" ]; then
    STRUCT_OK=1
    break
  fi
  sleep 4
done
check_criterion "Secret volume defaultMode corrected to 0444 (runAsUser: 1000 preserved), Pod Running" \
  [ "$STRUCT_OK" = "1" ]

CONTENT_OK=0
for _ in $(seq 1 12); do
  ACTUAL="$(kubectl exec "$POD" -c app -n "$QUESTION_ID" -- cat /handoff/tls.key 2>/dev/null)"
  if [ "$ACTUAL" = "sekret-key-value-9931" ]; then
    CONTENT_OK=1
    break
  fi
  sleep 3
done
check_criterion "'app' container's /handoff/tls.key contains the real Secret value 'sekret-key-value-9931'" \
  [ "$CONTENT_OK" = "1" ]

print_score
