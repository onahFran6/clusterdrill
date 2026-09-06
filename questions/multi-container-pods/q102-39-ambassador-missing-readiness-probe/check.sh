#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-39-ambassador-missing-readiness-probe${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

POD="ambassador-app"

# "ambassador" is already Ready (a few seconds after start) by the time
# check.sh usually runs even in the unsolved state - the bug is a startup
# race, not a steady-state symptom - so this grades the STRUCTURAL fix
# (a real readinessProbe now exists on port 8080) together with confirming
# the Pod still reaches steady-state 2/2 Running, exactly like every other
# probe-shape question in this bank.
STRUCT_OK=0
for _ in $(seq 1 24); do
  PROBE_PORT="$(kget pod "$POD" '{.spec.containers[?(@.name=="ambassador")].readinessProbe.tcpSocket.port}' -n "$QUESTION_ID")"
  AMB_READY="$(kget pod "$POD" '{.status.containerStatuses[?(@.name=="ambassador")].ready}' -n "$QUESTION_ID")"
  PHASE="$(kget pod "$POD" '{.status.phase}' -n "$QUESTION_ID")"
  APP_IMAGE="$(kget pod "$POD" '{.spec.containers[?(@.name=="app")].image}' -n "$QUESTION_ID")"
  AMB_IMAGE="$(kget pod "$POD" '{.spec.containers[?(@.name=="ambassador")].image}' -n "$QUESTION_ID")"

  if [ "$PROBE_PORT" = "8080" ] && [ "$AMB_READY" = "true" ] && [ "$PHASE" = "Running" ] \
     && [ "$APP_IMAGE" = "busybox:1.36" ] && [ "$AMB_IMAGE" = "busybox:1.36" ]; then
    STRUCT_OK=1
    break
  fi
  sleep 4
done
check_criterion "'ambassador' has a readinessProbe checking tcpSocket port 8080, reports ready, containers/images unchanged" \
  [ "$STRUCT_OK" = "1" ]

print_score
