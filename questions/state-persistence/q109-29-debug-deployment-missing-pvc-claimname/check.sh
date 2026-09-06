#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q109-29-debug-deployment-missing-pvc-claimname${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'orders-api' pod template volume claimName is 'orders-data'" \
  [ "$(kget deployment orders-api '{.spec.template.spec.volumes[0].persistentVolumeClaim.claimName}' -n "$QUESTION_ID")" = "orders-data" ]

ready_replicas="$(kget deployment orders-api '{.status.readyReplicas}' -n "$QUESTION_ID")"
check_criterion "Deployment 'orders-api' has at least 1 ready replica" \
  bash -c '[[ "$1" =~ ^[0-9]+$ ]] && (( $1 >= 1 ))' _ "$ready_replicas"

print_score
