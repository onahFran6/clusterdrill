#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-20-init-container-wrong-image-tag${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Unsolved state: fetch-config is stuck in ImagePullBackOff/ErrImagePull, so
# it never terminates and report-app never starts - both checks below are
# FALSE until the candidate actually fixes the image tag, satisfying the
# "unsolved state scores 0" gate.

check_criterion "Pod report-gen is Running with main container report-app ready" \
  bash -c '
    phase="$(kubectl get pod report-gen -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
    ready="$(kubectl get pod report-gen -n "'"$QUESTION_ID"'" -o jsonpath="{.status.containerStatuses[?(@.name==\"report-app\")].ready}" 2>/dev/null)"
    [ "$phase" = "Running" ] && [ "$ready" = "true" ]
  '

check_criterion "init container fetch-config lastState/status Terminated with reason Completed (exit code 0)" \
  bash -c '
    reason="$(kubectl get pod report-gen -n "'"$QUESTION_ID"'" -o jsonpath="{.status.initContainerStatuses[?(@.name==\"fetch-config\")].state.terminated.reason}" 2>/dev/null)"
    exitcode="$(kubectl get pod report-gen -n "'"$QUESTION_ID"'" -o jsonpath="{.status.initContainerStatuses[?(@.name==\"fetch-config\")].state.terminated.exitCode}" 2>/dev/null)"
    lastreason="$(kubectl get pod report-gen -n "'"$QUESTION_ID"'" -o jsonpath="{.status.initContainerStatuses[?(@.name==\"fetch-config\")].lastState.terminated.reason}" 2>/dev/null)"
    { [ "$reason" = "Completed" ] && [ "$exitcode" = "0" ]; } || [ "$lastreason" = "Completed" ]
  '

print_score
