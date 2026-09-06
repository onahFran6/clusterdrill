#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q107-46-livenessprobe-exec-array-vs-shell-pipeline${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'status-writer' livenessProbe now invokes a shell (sh -c) so its pipe is interpreted rather than passed as a literal exec argument, is Running with 0 restarts, and command/image unchanged" \
  bash -c '
    cmd0="$(kubectl get pod status-writer -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].livenessProbe.exec.command[0]}" 2>/dev/null)"
    cmd1="$(kubectl get pod status-writer -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].livenessProbe.exec.command[1]}" 2>/dev/null)"
    case "$cmd0" in
      sh|/bin/sh|bash|/bin/bash) : ;;
      *) exit 1 ;;
    esac
    [ "$cmd1" = "-c" ] || exit 1
    image="$(kubectl get pod status-writer -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].image}" 2>/dev/null)"
    [ "$image" = "busybox:1.36" ] || exit 1
    app_cmd="$(kubectl get pod status-writer -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].command[*]}" 2>/dev/null)"
    [ "$app_cmd" = "sh -c while true; do echo ok > /tmp/status; sleep 1; done" ] || exit 1
    phase="$(kubectl get pod status-writer -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
    [ "$phase" = "Running" ] || exit 1
    restarts="$(kubectl get pod status-writer -n "'"$QUESTION_ID"'" -o jsonpath="{.status.containerStatuses[0].restartCount}" 2>/dev/null)"
    [ "$restarts" = "0" ]
  '

print_score
