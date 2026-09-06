#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q107-02-readiness-httpget-basic${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'catalog-api' has an httpGet readinessProbe" \
  [ "$(kget pod catalog-api '{.spec.containers[0].readinessProbe.httpGet.path}' -n "$QUESTION_ID")" = "/" ]

check_criterion "readinessProbe httpGet targets port 80" \
  [ "$(kget pod catalog-api '{.spec.containers[0].readinessProbe.httpGet.port}' -n "$QUESTION_ID")" = "80" ]

check_criterion "readinessProbe periodSeconds is 5" \
  [ "$(kget pod catalog-api '{.spec.containers[0].readinessProbe.periodSeconds}' -n "$QUESTION_ID")" = "5" ]

check_criterion "readinessProbe failureThreshold is 3" \
  [ "$(kget pod catalog-api '{.spec.containers[0].readinessProbe.failureThreshold}' -n "$QUESTION_ID")" = "3" ]

print_score
