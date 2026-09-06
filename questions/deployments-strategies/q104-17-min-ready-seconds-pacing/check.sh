#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q104-17-min-ready-seconds-pacing${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'event-bus' has minReadySeconds=10" \
  [ "$(kget deployment event-bus '{.spec.minReadySeconds}' -n "$QUESTION_ID")" = "10" ]

check_criterion "Deployment 'event-bus' rolled out to nginx:1.25-alpine with 3 ready replicas" \
  bash -c '
    minready="$(kubectl get deployment event-bus -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.minReadySeconds}" 2>/dev/null)"
    image="$(kubectl get deployment event-bus -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    ready="$(kubectl get deployment event-bus -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    avail="$(kubectl get deployment event-bus -n "'"$QUESTION_ID"'" -o jsonpath="{.status.availableReplicas}" 2>/dev/null)"
    [ "$minready" = "10" ] && [ "$image" = "nginx:1.25-alpine" ] && [ "$ready" = "3" ] && [ "$avail" = "3" ]
  '

print_score
