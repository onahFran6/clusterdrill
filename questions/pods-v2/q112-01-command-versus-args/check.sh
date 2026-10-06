#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e` on purpose - see lib/grading.sh header comment.
set -uo pipefail

QUESTION_ID="q112-01-command-versus-args${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'heartbeat' exists, image busybox:1.36" \
  [ "$(kget pod heartbeat '{.spec.containers[0].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

check_criterion "Labels app=heartbeat,tier=tools are set" \
  bash -c '
    app="$(kubectl get pod heartbeat -n "'"$QUESTION_ID"'" -o jsonpath="{.metadata.labels.app}" 2>/dev/null)"
    tier="$(kubectl get pod heartbeat -n "'"$QUESTION_ID"'" -o jsonpath="{.metadata.labels.tier}" 2>/dev/null)"
    [ "$app" = "heartbeat" ] && [ "$tier" = "tools" ]
  '

check_criterion "command is exactly [\"sh\", \"-c\"]" \
  [ "$(kget pod heartbeat '{.spec.containers[0].command}' -n "$QUESTION_ID")" = '["sh","-c"]' ]

check_criterion "args[0] is the beat-from-io loop" \
  bash -c '
    args="$(kubectl get pod heartbeat -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].args[0]}" 2>/dev/null)"
    echo "$args" | grep -q "beat from io" && echo "$args" | grep -q "sleep 5"
  '

check_criterion "Pod is Running" \
  [ "$(kget pod heartbeat '{.status.phase}' -n "$QUESTION_ID")" = "Running" ]

check_criterion "Pod's own logs start with 'beat from io'" \
  bash -c '
    line="$(kubectl logs heartbeat -n "'"$QUESTION_ID"'" 2>/dev/null | head -1)"
    [ "$line" = "beat from io" ]
  '

print_score
