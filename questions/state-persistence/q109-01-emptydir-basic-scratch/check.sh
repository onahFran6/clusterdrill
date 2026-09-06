#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q109-01-emptydir-basic-scratch${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'render-worker' exists in $QUESTION_ID" \
  resource_exists pod render-worker -n "$QUESTION_ID"

volumes_json="$(kubectl get pod render-worker -n "$QUESTION_ID" -o jsonpath='{.spec.volumes}' 2>/dev/null)"

check_criterion "Pod has an emptyDir volume named 'scratch'" \
  bash -c '[[ "$1" == *"\"name\":\"scratch\""* && "$1" == *"\"emptyDir\""* ]]' _ "$volumes_json"

check_criterion "Container 'worker' mounts 'scratch' at /var/scratch" \
  [ "$(kget pod render-worker '{.spec.containers[0].volumeMounts[?(@.name=="scratch")].mountPath}' -n "$QUESTION_ID")" = "/var/scratch" ]

print_score
