#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q107-25-cascading-liveness-failure-dependent-service${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Env var LISTEN_PORT's configMapKeyRef.key is 'PORT'" \
  [ "$(kget pod orders-api '{.spec.containers[0].env[?(@.name=="LISTEN_PORT")].valueFrom.configMapKeyRef.key}' -n "$QUESTION_ID")" = "PORT" ]

check_criterion "Pod 'orders-api' container is Ready" \
  [ "$(kget pod orders-api '{.status.containerStatuses[0].ready}' -n "$QUESTION_ID")" = "true" ]

RESTARTS_BEFORE="$(kget pod orders-api '{.status.containerStatuses[0].restartCount}' -n "$QUESTION_ID")"
sleep 20
RESTARTS_AFTER="$(kget pod orders-api '{.status.containerStatuses[0].restartCount}' -n "$QUESTION_ID")"
READY_AFTER="$(kget pod orders-api '{.status.containerStatuses[0].ready}' -n "$QUESTION_ID")"

check_criterion "Pod 'orders-api' restart count is stable and container still Ready after a 20s recheck (liveness probe passing steadily)" \
  bash -c '[ "'"$READY_AFTER"'" = "true" ] && [ -n "'"$RESTARTS_BEFORE"'" ] && [ "'"$RESTARTS_BEFORE"'" = "'"$RESTARTS_AFTER"'" ]'

print_score
