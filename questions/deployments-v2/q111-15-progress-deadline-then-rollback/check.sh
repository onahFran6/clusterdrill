#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q111-15-progress-deadline-then-rollback${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "progressDeadlineSeconds is set to 60" \
  [ "$(kget deployment ring '{.spec.progressDeadlineSeconds}' -n "$QUESTION_ID")" = "60" ]

check_criterion "Deployment rolled back to the last working image nginx:1.25" \
  [ "$(kget deployment ring '{.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")" = "nginx:1.25" ]

check_criterion "All 4 pods are Ready again" \
  [ "$(kget deployment ring '{.status.readyReplicas}' -n "$QUESTION_ID")" = "4" ]

print_score
