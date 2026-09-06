#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q107-49-diagnose-two-simultaneous-crashloops-different-causes${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'worker-a' command typo fixed (sleep, not sleeep), image unchanged, Running and Ready" \
  bash -c '
    cmd="$(kubectl get pod worker-a -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].command[0]}" 2>/dev/null)"
    [ "$cmd" = "sleep" ] || exit 1
    image="$(kubectl get pod worker-a -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].image}" 2>/dev/null)"
    [ "$image" = "busybox:1.36" ] || exit 1
    ready="$(kubectl get pod worker-a -n "'"$QUESTION_ID"'" -o jsonpath="{.status.containerStatuses[0].ready}" 2>/dev/null)"
    [ "$ready" = "true" ]
  '

check_criterion "Pod 'worker-b' memory limit raised well above what stress needs (at least 200Mi), same stress args, Running and Ready" \
  bash -c '
    limit_raw="$(kubectl get pod worker-b -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].resources.limits.memory}" 2>/dev/null)"
    case "$limit_raw" in
      *Gi) limit_mi=$(( ${limit_raw%Gi} * 1024 )) ;;
      *Mi) limit_mi="${limit_raw%Mi}" ;;
      *) exit 1 ;;
    esac
    [ "$limit_mi" -ge 200 ] 2>/dev/null || exit 1
    args="$(kubectl get pod worker-b -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].args[*]}" 2>/dev/null)"
    [ "$args" = "--vm 1 --vm-bytes 150M --vm-hang 1" ] || exit 1
    ready="$(kubectl get pod worker-b -n "'"$QUESTION_ID"'" -o jsonpath="{.status.containerStatuses[0].ready}" 2>/dev/null)"
    [ "$ready" = "true" ]
  '

print_score
