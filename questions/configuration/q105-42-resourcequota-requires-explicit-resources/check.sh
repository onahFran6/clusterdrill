#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-42-resourcequota-requires-explicit-resources${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'worker' exists (image busybox:1.36)" \
  [ "$(kget pod worker '{.spec.containers[0].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

check_criterion "Pod 'worker' is Running" \
  bash -c '
    phase="$(kubectl get pod worker -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
    [ "$phase" = "Running" ]
  '

check_criterion "Pod 'worker' explicitly sets requests.cpu, requests.memory, limits.cpu, and limits.memory" \
  bash -c '
    [ -n "$(kubectl get pod worker -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].resources.requests.cpu}" 2>/dev/null)" ] || exit 1
    [ -n "$(kubectl get pod worker -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].resources.requests.memory}" 2>/dev/null)" ] || exit 1
    [ -n "$(kubectl get pod worker -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].resources.limits.cpu}" 2>/dev/null)" ] || exit 1
    [ -n "$(kubectl get pod worker -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].resources.limits.memory}" 2>/dev/null)" ]
  '

print_score
