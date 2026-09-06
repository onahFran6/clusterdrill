#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q107-15-ready-not-live-distinguish${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "readinessProbe httpGet path fixed to '/'" \
  [ "$(kget pod search-svc '{.spec.containers[0].readinessProbe.httpGet.path}' -n "$QUESTION_ID")" = "/" ]

check_criterion "Pod 'search-svc' container is now Ready" \
  [ "$(kget pod search-svc '{.status.containerStatuses[0].ready}' -n "$QUESTION_ID")" = "true" ]

print_score
