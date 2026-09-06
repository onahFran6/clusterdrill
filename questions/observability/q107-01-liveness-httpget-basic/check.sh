#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e` - a failed criterion is a
# normal result, not a script error (see lib/grading.sh header).
set -uo pipefail

QUESTION_ID="q107-01-liveness-httpget-basic${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'web-front' has an httpGet livenessProbe" \
  [ "$(kget pod web-front '{.spec.containers[0].livenessProbe.httpGet.path}' -n "$QUESTION_ID")" = "/" ]

check_criterion "livenessProbe httpGet targets port 80" \
  [ "$(kget pod web-front '{.spec.containers[0].livenessProbe.httpGet.port}' -n "$QUESTION_ID")" = "80" ]

check_criterion "livenessProbe initialDelaySeconds is 5" \
  [ "$(kget pod web-front '{.spec.containers[0].livenessProbe.initialDelaySeconds}' -n "$QUESTION_ID")" = "5" ]

check_criterion "livenessProbe periodSeconds is 10" \
  [ "$(kget pod web-front '{.spec.containers[0].livenessProbe.periodSeconds}' -n "$QUESTION_ID")" = "10" ]

print_score
