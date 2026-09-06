#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-13-resourcequota-namespace${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "ResourceQuota 'team-quota' exists" \
  resource_exists resourcequota team-quota -n "$QUESTION_ID"

check_criterion "hard.requests.cpu is 1" \
  [ "$(kget resourcequota team-quota '{.spec.hard.requests\.cpu}' -n "$QUESTION_ID")" = "1" ]

check_criterion "hard.requests.memory is 1Gi" \
  [ "$(kget resourcequota team-quota '{.spec.hard.requests\.memory}' -n "$QUESTION_ID")" = "1Gi" ]

check_criterion "hard.limits.cpu is 2" \
  [ "$(kget resourcequota team-quota '{.spec.hard.limits\.cpu}' -n "$QUESTION_ID")" = "2" ]

check_criterion "hard.limits.memory is 2Gi" \
  [ "$(kget resourcequota team-quota '{.spec.hard.limits\.memory}' -n "$QUESTION_ID")" = "2Gi" ]

check_criterion "hard.pods is 5" \
  [ "$(kget resourcequota team-quota '{.spec.hard.pods}' -n "$QUESTION_ID")" = "5" ]

print_score
