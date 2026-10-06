#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e` on purpose - see lib/grading.sh header comment.
set -uo pipefail

QUESTION_ID="q112-17-restart-policies-and-exit-codes${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "'once' (restartPolicy=Never) reaches Succeeded with exitCode 0, never restarts" \
  bash -c '
    for i in $(seq 1 15); do
      phase="$(kubectl get pod once -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
      exitcode="$(kubectl get pod once -n "'"$QUESTION_ID"'" -o jsonpath="{.status.containerStatuses[0].state.terminated.exitCode}" 2>/dev/null)"
      restarts="$(kubectl get pod once -n "'"$QUESTION_ID"'" -o jsonpath="{.status.containerStatuses[0].restartCount}" 2>/dev/null)"
      [ "$phase" = "Succeeded" ] && [ "$exitcode" = "0" ] && [ "$restarts" = "0" ] && exit 0
      sleep 2
    done
    exit 1
  '

check_criterion "'once' has restartPolicy Never" \
  bash -c '[ "$(kubectl get pod once -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.restartPolicy}" 2>/dev/null)" = "Never" ]'

check_criterion "'retry' (restartPolicy=OnFailure) stays Running and restarts after exiting 2" \
  bash -c '
    policy="$(kubectl get pod retry -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.restartPolicy}" 2>/dev/null)"
    [ "$policy" = "OnFailure" ] || exit 1
    for i in $(seq 1 20); do
      phase="$(kubectl get pod retry -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
      restarts="$(kubectl get pod retry -n "'"$QUESTION_ID"'" -o jsonpath="{.status.containerStatuses[0].restartCount}" 2>/dev/null)"
      [ "$phase" = "Running" ] && [ -n "$restarts" ] && [ "$restarts" -gt 0 ] && exit 0
      sleep 3
    done
    exit 1
  '

check_criterion "'forever' (default restartPolicy) stays Running and restarts after exiting 0" \
  bash -c '
    policy="$(kubectl get pod forever -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.restartPolicy}" 2>/dev/null)"
    [ "$policy" = "Always" ] || exit 1
    for i in $(seq 1 20); do
      phase="$(kubectl get pod forever -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
      restarts="$(kubectl get pod forever -n "'"$QUESTION_ID"'" -o jsonpath="{.status.containerStatuses[0].restartCount}" 2>/dev/null)"
      [ "$phase" = "Running" ] && [ -n "$restarts" ] && [ "$restarts" -gt 0 ] && exit 0
      sleep 3
    done
    exit 1
  '

check_criterion "All three Pods are busybox:1.36" \
  bash -c '
    for p in once retry forever; do
      img="$(kubectl get pod "$p" -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].image}" 2>/dev/null)"
      [ "$img" = "busybox:1.36" ] || exit 1
    done
  '

print_score
