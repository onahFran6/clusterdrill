#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q107-04-exec-liveness-probe${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

exec_cmd_0="$(kget pod file-watcher '{.spec.containers[0].livenessProbe.exec.command[0]}' -n "$QUESTION_ID")"
exec_cmd_1="$(kget pod file-watcher '{.spec.containers[0].livenessProbe.exec.command[1]}' -n "$QUESTION_ID")"

check_criterion "livenessProbe uses exec (not httpGet/tcpSocket)" \
  [ -n "$exec_cmd_0" ]

check_criterion "exec command checks /tmp/healthy via 'cat'" \
  bash -c "[ '$exec_cmd_0' = 'cat' ] && [ '$exec_cmd_1' = '/tmp/healthy' ]"

check_criterion "livenessProbe initialDelaySeconds is 5" \
  [ "$(kget pod file-watcher '{.spec.containers[0].livenessProbe.initialDelaySeconds}' -n "$QUESTION_ID")" = "5" ]

check_criterion "livenessProbe periodSeconds is 10" \
  [ "$(kget pod file-watcher '{.spec.containers[0].livenessProbe.periodSeconds}' -n "$QUESTION_ID")" = "10" ]

print_score
