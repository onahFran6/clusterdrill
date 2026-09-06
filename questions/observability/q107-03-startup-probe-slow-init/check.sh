#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q107-03-startup-probe-slow-init${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Container has a startupProbe with httpGet path '/'" \
  [ "$(kget pod legacy-monolith '{.spec.containers[0].startupProbe.httpGet.path}' -n "$QUESTION_ID")" = "/" ]

check_criterion "startupProbe httpGet targets port 80" \
  [ "$(kget pod legacy-monolith '{.spec.containers[0].startupProbe.httpGet.port}' -n "$QUESTION_ID")" = "80" ]

check_criterion "startupProbe periodSeconds is 10" \
  [ "$(kget pod legacy-monolith '{.spec.containers[0].startupProbe.periodSeconds}' -n "$QUESTION_ID")" = "10" ]

check_criterion "startupProbe failureThreshold is 9" \
  [ "$(kget pod legacy-monolith '{.spec.containers[0].startupProbe.failureThreshold}' -n "$QUESTION_ID")" = "9" ]

print_score
