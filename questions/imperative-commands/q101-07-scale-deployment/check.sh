#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q101-07-scale-deployment${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'worker-pool' has 5 replicas configured" \
  [ "$(kget deployment worker-pool '{.spec.replicas}' -n "$QUESTION_ID")" = "5" ]

check_criterion "Deployment 'worker-pool' has 5 ready replicas" \
  [ "$(kget deployment worker-pool '{.status.readyReplicas}' -n "$QUESTION_ID")" = "5" ]

print_score
