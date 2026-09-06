#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q101-14-edit-live-deployment${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'live-edit' has 4 replicas configured" \
  [ "$(kget deployment live-edit '{.spec.replicas}' -n "$QUESTION_ID")" = "4" ]

check_criterion "Deployment 'live-edit' has 4 ready replicas" \
  [ "$(kget deployment live-edit '{.status.readyReplicas}' -n "$QUESTION_ID")" = "4" ]

print_score
