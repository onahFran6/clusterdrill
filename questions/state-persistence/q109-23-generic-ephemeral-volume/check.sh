#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q109-23-generic-ephemeral-volume${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'ephemeral-app' exists in $QUESTION_ID" \
  resource_exists pod ephemeral-app -n "$QUESTION_ID"

check_criterion "Pod 'ephemeral-app' is Running" \
  [ "$(kget pod ephemeral-app '{.status.phase}' -n "$QUESTION_ID")" = "Running" ]

check_criterion "Volume 'scratch' is a generic ephemeral volume requesting 50Mi ReadWriteOnce" \
  [ "$(kget pod ephemeral-app '{.spec.volumes[?(@.name=="scratch")].ephemeral.volumeClaimTemplate.spec.resources.requests.storage}' -n "$QUESTION_ID")" = "50Mi" ]

check_criterion "Container mounts 'scratch' volume at /scratch" \
  [ "$(kget pod ephemeral-app '{.spec.containers[0].volumeMounts[?(@.name=="scratch")].mountPath}' -n "$QUESTION_ID")" = "/scratch" ]

check_criterion "Auto-created PVC 'ephemeral-app-scratch' exists" \
  resource_exists pvc ephemeral-app-scratch -n "$QUESTION_ID"

check_criterion "PVC 'ephemeral-app-scratch' is Bound" \
  [ "$(kget pvc ephemeral-app-scratch '{.status.phase}' -n "$QUESTION_ID")" = "Bound" ]

print_score
