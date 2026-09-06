#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-38-readiness-probe-wrong-container-port${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

POD="probe-mixup"

# sidecar-metrics is already Running/Ready in the unsolved state, so overall
# Running-ness alone can't be the criterion - poll for the SPECIFIC proof:
# web's probe port corrected to 80 AND web itself actually Ready.
STRUCT_OK=0
for _ in $(seq 1 30); do
  PROBE_PORT="$(kget pod "$POD" '{.spec.containers[?(@.name=="web")].readinessProbe.tcpSocket.port}' -n "$QUESTION_ID")"
  WEB_READY="$(kget pod "$POD" '{.status.containerStatuses[?(@.name=="web")].ready}' -n "$QUESTION_ID")"
  PHASE="$(kget pod "$POD" '{.status.phase}' -n "$QUESTION_ID")"
  WEB_IMAGE="$(kget pod "$POD" '{.spec.containers[?(@.name=="web")].image}' -n "$QUESTION_ID")"
  SIDECAR_IMAGE="$(kget pod "$POD" '{.spec.containers[?(@.name=="sidecar-metrics")].image}' -n "$QUESTION_ID")"

  if [ "$PROBE_PORT" = "80" ] && [ "$WEB_READY" = "true" ] && [ "$PHASE" = "Running" ] \
     && [ "$WEB_IMAGE" = "nginx:1.27-alpine" ] && [ "$SIDECAR_IMAGE" = "busybox:1.36" ]; then
    STRUCT_OK=1
    break
  fi
  sleep 4
done
check_criterion "'web' readinessProbe.tcpSocket.port corrected to 80, 'web' reports ready, Pod Running, containers/images unchanged" \
  [ "$STRUCT_OK" = "1" ]

check_criterion "Pod 'probe-mixup' is 2/2 Running (both containers ready)" \
  bash -c "
    ready=\$(kubectl get pod '$POD' -n '$QUESTION_ID' -o jsonpath='{.status.containerStatuses[*].ready}' 2>/dev/null)
    [ \"\$(echo \"\$ready\" | tr ' ' '\n' | grep -c '^true\$')\" = '2' ]
  "

print_score
