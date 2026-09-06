#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-45-sidecar-runasnonroot-config-error${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

POD="hardened-app"

# "app" is already Running/Ready in the unsolved state, so Running-ness
# alone can't be the criterion - poll for the specific proof: sidecar has
# its own runAsUser AND actually reaches Ready.
STRUCT_OK=0
for _ in $(seq 1 30); do
  SIDECAR_UID="$(kget pod "$POD" '{.spec.containers[?(@.name=="sidecar")].securityContext.runAsUser}' -n "$QUESTION_ID")"
  POD_NONROOT="$(kget pod "$POD" '{.spec.securityContext.runAsNonRoot}' -n "$QUESTION_ID")"
  APP_UID="$(kget pod "$POD" '{.spec.containers[?(@.name=="app")].securityContext.runAsUser}' -n "$QUESTION_ID")"
  SIDECAR_READY="$(kget pod "$POD" '{.status.containerStatuses[?(@.name=="sidecar")].ready}' -n "$QUESTION_ID")"
  PHASE="$(kget pod "$POD" '{.status.phase}' -n "$QUESTION_ID")"
  APP_IMAGE="$(kget pod "$POD" '{.spec.containers[?(@.name=="app")].image}' -n "$QUESTION_ID")"
  SIDECAR_IMAGE="$(kget pod "$POD" '{.spec.containers[?(@.name=="sidecar")].image}' -n "$QUESTION_ID")"

  if [ "$SIDECAR_UID" = "1000" ] && [ "$POD_NONROOT" = "true" ] && [ "$APP_UID" = "1000" ] \
     && [ "$SIDECAR_READY" = "true" ] && [ "$PHASE" = "Running" ] \
     && [ "$APP_IMAGE" = "busybox:1.36" ] && [ "$SIDECAR_IMAGE" = "busybox:1.36" ]; then
    STRUCT_OK=1
    break
  fi
  sleep 4
done
check_criterion "'sidecar' has securityContext.runAsUser: 1000, Pod-level runAsNonRoot/app unchanged, 'sidecar' reports ready" \
  [ "$STRUCT_OK" = "1" ]

check_criterion "Pod 'hardened-app' is 2/2 Running" \
  bash -c "
    ready=\$(kubectl get pod '$POD' -n '$QUESTION_ID' -o jsonpath='{.status.containerStatuses[*].ready}' 2>/dev/null)
    [ \"\$(echo \"\$ready\" | tr ' ' '\n' | grep -c '^true\$')\" = '2' ]
  "

print_score
