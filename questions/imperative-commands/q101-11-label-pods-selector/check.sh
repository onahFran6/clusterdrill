#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q101-11-label-pods-selector${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'batch-a' has label env=staging" \
  [ "$(kget pod batch-a '{.metadata.labels.env}' -n "$QUESTION_ID")" = "staging" ]

check_criterion "Pod 'batch-b' has label env=staging" \
  [ "$(kget pod batch-b '{.metadata.labels.env}' -n "$QUESTION_ID")" = "staging" ]

batch_a_retains_role_and_has_env() {
  [ "$(kget pod batch-a '{.metadata.labels.role}' -n "$QUESTION_ID")" = "worker" ] &&
    [ "$(kget pod batch-a '{.metadata.labels.env}' -n "$QUESTION_ID")" = "staging" ]
}

check_criterion "Pod 'batch-a' was not deleted/recreated (still has role=worker alongside env)" \
  batch_a_retains_role_and_has_env

print_score
