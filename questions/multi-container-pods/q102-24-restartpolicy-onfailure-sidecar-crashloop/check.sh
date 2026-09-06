#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-24-restartpolicy-onfailure-sidecar-crashloop${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# "stream-proc" always exists and "log-tailer" always has restartPolicy
# Always (setup.sh already sets both correctly and the candidate never
# touches them), and the Pod's own phase stays "Running" throughout even
# while worker crash-loops - so none of that can be its own criterion, or
# this would score before the candidate fixes anything. Bundle the stable
# baseline into the SAME criterion as the one thing that actually changes:
# worker's restartCount staying flat across a live poll window, which is
# false in the unsolved state (worker keeps crash-looping every ~10s) and
# only becomes true once the candidate fixes worker's script.
worker_stable_and_healthy() {
  local i phase sidecar_state sidecar_restart_policy pod_stable
  pod_stable=0
  for ((i = 0; i < 24; i++)); do
    phase="$(kget pod stream-proc '{.status.phase}' -n "$QUESTION_ID" 2>/dev/null)"
    sidecar_state="$(kget pod stream-proc '{.status.initContainerStatuses[?(@.name=="log-tailer")].state.running}' -n "$QUESTION_ID" 2>/dev/null)"
    sidecar_restart_policy="$(kget pod stream-proc '{.spec.initContainers[?(@.name=="log-tailer")].restartPolicy}' -n "$QUESTION_ID" 2>/dev/null)"
    if [ "$phase" = "Running" ] && [ -n "$sidecar_state" ] && [ "$sidecar_restart_policy" = "Always" ]; then
      pod_stable=1
      break
    fi
    sleep 5
  done
  [ "$pod_stable" = "1" ] || return 1

  local initial_restarts current_restarts
  initial_restarts="$(kget pod stream-proc '{.status.containerStatuses[?(@.name=="worker")].restartCount}' -n "$QUESTION_ID" 2>/dev/null)"
  initial_restarts="${initial_restarts:-0}"

  for ((i = 0; i < 5; i++)); do
    sleep 5
    current_restarts="$(kget pod stream-proc '{.status.containerStatuses[?(@.name=="worker")].restartCount}' -n "$QUESTION_ID" 2>/dev/null)"
    current_restarts="${current_restarts:-0}"
    if [ "$current_restarts" != "$initial_restarts" ]; then
      return 1
    fi
  done
  return 0
}

check_criterion "Pod 'stream-proc' Running with native sidecar 'log-tailer' healthy, and worker's restartCount flat over a 20s+ poll window" \
  worker_stable_and_healthy

print_score
