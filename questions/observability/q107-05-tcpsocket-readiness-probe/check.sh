#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q107-05-tcpsocket-readiness-probe${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "readinessProbe uses tcpSocket on port 6379" \
  [ "$(kget pod cache-node '{.spec.containers[0].readinessProbe.tcpSocket.port}' -n "$QUESTION_ID")" = "6379" ]

check_criterion "readinessProbe initialDelaySeconds is 5" \
  [ "$(kget pod cache-node '{.spec.containers[0].readinessProbe.initialDelaySeconds}' -n "$QUESTION_ID")" = "5" ]

check_criterion "readinessProbe periodSeconds is 10" \
  [ "$(kget pod cache-node '{.spec.containers[0].readinessProbe.periodSeconds}' -n "$QUESTION_ID")" = "10" ]

print_score
