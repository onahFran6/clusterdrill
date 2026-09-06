#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-29-limitrange-rebalance-prevent-sidecar-oomkill${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# mem_to_mi <quantity> - strips a trailing "Mi" suffix and prints the bare
# integer, or prints nothing if the quantity isn't Mi-suffixed. Every value
# this question's setup.sh/ANSWER.md ever writes uses "Mi", so this is
# sufficient for the range checks below.
mem_to_mi() {
  local q="$1"
  if [[ "$q" =~ ^([0-9]+)Mi$ ]]; then
    echo "${BASH_REMATCH[1]}"
  fi
}

# "batch-processor" always exists right after setup.sh, both container
# names/images/commands never change, and the LimitRange's own max is
# never touched by the candidate - all trivially true pre-solve, so none
# of that is its own criterion. The one thing that actually changes is
# whether "main" can complete its real ~86Mi workload without being
# OOMKilled - and per this question's own ground rules, that must be
# proven by LIVE observation (watching for a restart / OOMKilled reason
# to actually happen), not by statically reading the YAML numbers.
#
# In the unsolved state, main's 24Mi limit crash-loops it almost
# immediately and repeatedly (verified empirically: first OOMKill lands
# within a few seconds, well inside the poll window below). Once
# genuinely fixed, main never restarts at all across the same window - so
# a single "no restart/OOM observed across a live poll window, and the
# container is actually Running/Ready right now" check correctly scores 0
# before the fix and full marks after it, without ever hand-waving past
# the live behavior.
main_healthy_no_oom_under_real_load() {
  local i phase up=0

  for ((i = 0; i < 12; i++)); do
    phase="$(kget pod batch-processor '{.status.phase}' -n "$QUESTION_ID" 2>/dev/null)"
    if [ -n "$phase" ]; then
      up=1
      break
    fi
    sleep 5
  done
  [ "$up" = "1" ] || return 1

  local initial_restarts current_restarts last_reason
  initial_restarts="$(kget pod batch-processor '{.status.containerStatuses[?(@.name=="main")].restartCount}' -n "$QUESTION_ID" 2>/dev/null)"
  initial_restarts="${initial_restarts:-0}"

  for ((i = 0; i < 20; i++)); do
    sleep 5
    current_restarts="$(kget pod batch-processor '{.status.containerStatuses[?(@.name=="main")].restartCount}' -n "$QUESTION_ID" 2>/dev/null)"
    current_restarts="${current_restarts:-0}"
    last_reason="$(kget pod batch-processor '{.status.containerStatuses[?(@.name=="main")].lastState.terminated.reason}' -n "$QUESTION_ID" 2>/dev/null)"
    if [ "$current_restarts" != "$initial_restarts" ] || [ "$last_reason" = "OOMKilled" ]; then
      return 1
    fi
  done

  phase="$(kget pod batch-processor '{.status.phase}' -n "$QUESTION_ID" 2>/dev/null)"
  local ready
  ready="$(kget pod batch-processor '{.status.containerStatuses[?(@.name=="main")].ready}' -n "$QUESTION_ID" 2>/dev/null)"
  [ "$phase" = "Running" ] && [ "$ready" = "true" ]
}

check_criterion "Container 'main' never gets OOMKilled/restarted across a sustained live poll window while running its real ~86Mi workload, and is Running/Ready" \
  main_healthy_no_oom_under_real_load

# Independent structural fact: the two containers' own memory limits have
# actually been rebalanced (not just "main happens to be healthy" for some
# unrelated reason). This is false immediately after setup.sh - main sits
# at 24Mi and sidecar at 112Mi - and only becomes true once the candidate
# both raises main's own limit into a safe range at/under the namespace's
# 128Mi ceiling AND meaningfully lowers the sidecar's oversized one below
# main's. All four numbers are read from live cluster state, never a
# client-supplied flag.
rebalanced_correctly() {
  local main_lim_raw main_req_raw side_lim_raw side_req_raw
  local main_lim main_req side_lim side_req

  main_lim_raw="$(kget pod batch-processor '{.spec.containers[?(@.name=="main")].resources.limits.memory}' -n "$QUESTION_ID" 2>/dev/null)"
  main_req_raw="$(kget pod batch-processor '{.spec.containers[?(@.name=="main")].resources.requests.memory}' -n "$QUESTION_ID" 2>/dev/null)"
  side_lim_raw="$(kget pod batch-processor '{.spec.containers[?(@.name=="metrics-sidecar")].resources.limits.memory}' -n "$QUESTION_ID" 2>/dev/null)"
  side_req_raw="$(kget pod batch-processor '{.spec.containers[?(@.name=="metrics-sidecar")].resources.requests.memory}' -n "$QUESTION_ID" 2>/dev/null)"

  main_lim="$(mem_to_mi "$main_lim_raw")"
  main_req="$(mem_to_mi "$main_req_raw")"
  side_lim="$(mem_to_mi "$side_lim_raw")"
  side_req="$(mem_to_mi "$side_req_raw")"

  [ -n "$main_lim" ] && [ -n "$main_req" ] && [ -n "$side_lim" ] && [ -n "$side_req" ] || return 1

  # main: raised well above its broken 24Mi, at or under the 128Mi ceiling,
  # with enough headroom over its real ~86Mi (85.83Mi) buffer to actually
  # succeed (verified empirically at 120Mi; require at least 100Mi so a
  # too-thin fix doesn't accidentally pass this static check while still
  # flaking under main_healthy_no_oom_under_real_load above).
  [ "$main_lim" -ge 100 ] && [ "$main_lim" -le 128 ] || return 1
  [ "$main_req" -le "$main_lim" ] || return 1

  # sidecar: meaningfully lowered from its wasteful 112Mi, down to a value
  # that actually matches its own tiny footprint.
  [ "$side_lim" -le 48 ] && [ "$side_lim" -ge 8 ] || return 1
  [ "$side_req" -le "$side_lim" ] || return 1

  # The rebalance itself: main now holds the larger share, sidecar no
  # longer hoards headroom near the ceiling.
  [ "$main_lim" -gt "$side_lim" ] || return 1

  local main_image side_image
  main_image="$(kget pod batch-processor '{.spec.containers[?(@.name=="main")].image}' -n "$QUESTION_ID" 2>/dev/null)"
  side_image="$(kget pod batch-processor '{.spec.containers[?(@.name=="metrics-sidecar")].image}' -n "$QUESTION_ID" 2>/dev/null)"
  [ "$main_image" = "busybox:1.36" ] && [ "$side_image" = "busybox:1.36" ]
}

check_criterion "Container 'main's memory limit was raised to a safe value at/under the LimitRange's 128Mi ceiling and 'metrics-sidecar's was lowered to match its real footprint, with 'main' now holding the larger share" \
  rebalanced_correctly

print_score
