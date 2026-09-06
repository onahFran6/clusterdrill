#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q107-06-tune-probe-timing-flaky${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "livenessProbe periodSeconds is 10" \
  [ "$(kget pod report-generator '{.spec.containers[0].livenessProbe.periodSeconds}' -n "$QUESTION_ID")" = "10" ]

check_criterion "livenessProbe failureThreshold is 3" \
  [ "$(kget pod report-generator '{.spec.containers[0].livenessProbe.failureThreshold}' -n "$QUESTION_ID")" = "3" ]

check_criterion "livenessProbe timeoutSeconds is 5" \
  [ "$(kget pod report-generator '{.spec.containers[0].livenessProbe.timeoutSeconds}' -n "$QUESTION_ID")" = "5" ]

print_score
