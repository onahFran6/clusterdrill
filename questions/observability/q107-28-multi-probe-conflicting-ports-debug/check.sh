#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q107-28-multi-probe-conflicting-ports-debug${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "startupProbe httpGet.port is 8081" \
  [ "$(kget pod payments-gw '{.spec.containers[0].startupProbe.httpGet.port}' -n "$QUESTION_ID")" = "8081" ]

check_criterion "livenessProbe httpGet.port is 8081" \
  [ "$(kget pod payments-gw '{.spec.containers[0].livenessProbe.httpGet.port}' -n "$QUESTION_ID")" = "8081" ]

check_criterion "readinessProbe httpGet.port is 8081" \
  [ "$(kget pod payments-gw '{.spec.containers[0].readinessProbe.httpGet.port}' -n "$QUESTION_ID")" = "8081" ]

# Give the (possibly just-fixed) probes a little time to catch up before
# grading readiness/stability - a freshly-applied pod can take a few
# seconds to pass startupProbe -> readinessProbe.
for _ in $(seq 1 24); do
  ready="$(kget pod payments-gw '{.status.containerStatuses[0].ready}' -n "$QUESTION_ID")"
  [ "$ready" = "true" ] && break
  sleep 5
done

# Bundled ("ready" AND "restartCount stable") into one criterion - a
# standalone restartCount-stability check trivially passes on the unsolved
# state too (misconfigured probes leave it NotReady but not necessarily
# crash-looping, so restartCount can sit at 0 the whole time regardless of
# whether the candidate fixed anything). Gating stability on ready=true
# first makes this correctly score 0 pre-solve.
restart_count_1="$(kget pod payments-gw '{.status.containerStatuses[0].restartCount}' -n "$QUESTION_ID")"
sleep 15
restart_count_2="$(kget pod payments-gw '{.status.containerStatuses[0].restartCount}' -n "$QUESTION_ID")"

check_criterion "payments-gw container is ready AND its restartCount stayed stable across a 15s recheck (no crash loop)" \
  bash -c '[ "'"$(kget pod payments-gw '{.status.containerStatuses[0].ready}' -n "$QUESTION_ID")"'" = "true" ] && [ -n "'"$restart_count_1"'" ] && [ "'"$restart_count_1"'" = "'"$restart_count_2"'" ]'

print_score
