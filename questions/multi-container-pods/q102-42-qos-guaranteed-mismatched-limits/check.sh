#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-42-qos-guaranteed-mismatched-limits${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

POD="guaranteed-app"

# Both containers are already Running fine in the unsolved state (nothing
# crashes) - bundle the QoS-class fix with Running into ONE criterion.
STRUCT_OK=0
for _ in $(seq 1 24); do
  QOS="$(kget pod "$POD" '{.status.qosClass}' -n "$QUESTION_ID")"
  PHASE="$(kget pod "$POD" '{.status.phase}' -n "$QUESTION_ID")"
  READY_FLAGS="$(kget pod "$POD" '{.status.containerStatuses[*].ready}' -n "$QUESTION_ID")"
  READY_COUNT="$(echo "$READY_FLAGS" | tr ' ' '\n' | grep -c '^true$' 2>/dev/null || true)"
  APP_IMAGE="$(kget pod "$POD" '{.spec.containers[?(@.name=="app")].image}' -n "$QUESTION_ID")"
  CACHE_IMAGE="$(kget pod "$POD" '{.spec.containers[?(@.name=="cache")].image}' -n "$QUESTION_ID")"

  if [ "$QOS" = "Guaranteed" ] && [ "$PHASE" = "Running" ] && [ "$READY_COUNT" = "2" ] \
     && [ "$APP_IMAGE" = "busybox:1.36" ] && [ "$CACHE_IMAGE" = "busybox:1.36" ]; then
    STRUCT_OK=1
    break
  fi
  sleep 4
done
check_criterion "Pod's overall QoS class is 'Guaranteed' (every container's requests == limits), 2/2 Running, containers/images unchanged" \
  [ "$STRUCT_OK" = "1" ]

check_criterion "'cache' container's requests exactly equal its limits (cpu and memory)" \
  bash -c "
    rc=\$(kubectl get pod '$POD' -n '$QUESTION_ID' -o jsonpath='{.spec.containers[?(@.name==\"cache\")].resources.requests.cpu}')
    lc=\$(kubectl get pod '$POD' -n '$QUESTION_ID' -o jsonpath='{.spec.containers[?(@.name==\"cache\")].resources.limits.cpu}')
    rm=\$(kubectl get pod '$POD' -n '$QUESTION_ID' -o jsonpath='{.spec.containers[?(@.name==\"cache\")].resources.requests.memory}')
    lm=\$(kubectl get pod '$POD' -n '$QUESTION_ID' -o jsonpath='{.spec.containers[?(@.name==\"cache\")].resources.limits.memory}')
    [ \"\$rc\" = \"\$lc\" ] && [ \"\$rm\" = \"\$lm\" ] && [ -n \"\$rc\" ] && [ -n \"\$rm\" ]
  "

print_score
