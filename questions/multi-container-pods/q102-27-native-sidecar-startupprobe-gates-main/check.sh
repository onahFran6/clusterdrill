#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-27-native-sidecar-startupprobe-gates-main${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

INIT_NAME="$(kget pod gated-app '{.spec.initContainers[0].name}' -n "$QUESTION_ID")"
INIT_IMAGE="$(kget pod gated-app '{.spec.initContainers[0].image}' -n "$QUESTION_ID")"
INIT_RESTART_POLICY="$(kget pod gated-app '{.spec.initContainers[0].restartPolicy}' -n "$QUESTION_ID")"
INIT_COUNT="$(kget pod gated-app '{.spec.initContainers[*].name}' -n "$QUESTION_ID" | wc -w | tr -d ' ')"
PROBE_CMD="$(kget pod gated-app '{.spec.initContainers[0].startupProbe.exec.command}' -n "$QUESTION_ID")"
MAIN_COUNT="$(kget pod gated-app '{.spec.containers[*].name}' -n "$QUESTION_ID" | wc -w | tr -d ' ')"
MAIN_IMAGE="$(kget pod gated-app '{.spec.containers[?(@.name=="web")].image}' -n "$QUESTION_ID")"

# All of the sidecar's shape (name/image/restartPolicy) and web's
# name/count/image are set correctly by setup.sh and never touched by the
# candidate - trivially true even in the unsolved state. Poll for a single
# STABLE snapshot where init_started, main_started, phase, and ready_count
# are all read together (not across separate stale reads) and everything
# holds simultaneously, so nothing scores until the real fix (repointing
# the startupProbe at the real marker path) actually lands and propagates
# all the way through to the main container being Ready.
gated_app_fully_up() {
  local i init_started main_started phase ready_flags ready_count

  [ "$INIT_COUNT" = "1" ] || return 1
  [ "$INIT_NAME" = "cache-warmer" ] || return 1
  [ "$INIT_IMAGE" = "busybox:1.36" ] || return 1
  [ "$INIT_RESTART_POLICY" = "Always" ] || return 1
  echo "$PROBE_CMD" | grep -q '/var/run/warmer/ready' || return 1
  echo "$PROBE_CMD" | grep -q '/var/run/cache/ready' && return 1
  [ "$MAIN_COUNT" = "1" ] || return 1
  [ "$MAIN_IMAGE" = "nginx:1.27-alpine" ] || return 1

  # .status.containerStatuses only ever lists regular (non-init)
  # containers - a native sidecar (an initContainer, even with
  # restartPolicy: Always) is tracked under .status.initContainerStatuses
  # instead, so containerStatuses[*].ready can never reach 2 here even
  # when everything is healthy (there's exactly one regular container:
  # "web"). Grade the sidecar's own readiness separately.
  for ((i = 0; i < 48; i++)); do
    init_started="$(kget pod gated-app '{.status.initContainerStatuses[0].started}' -n "$QUESTION_ID" 2>/dev/null)"
    init_ready="$(kget pod gated-app '{.status.initContainerStatuses[0].ready}' -n "$QUESTION_ID" 2>/dev/null)"
    main_started="$(kget pod gated-app '{.status.containerStatuses[?(@.name=="web")].started}' -n "$QUESTION_ID" 2>/dev/null)"
    main_ready="$(kget pod gated-app '{.status.containerStatuses[?(@.name=="web")].ready}' -n "$QUESTION_ID" 2>/dev/null)"
    phase="$(kget pod gated-app '{.status.phase}' -n "$QUESTION_ID" 2>/dev/null)"
    if [ "$init_started" = "true" ] && [ "$init_ready" = "true" ] \
      && [ "$main_started" = "true" ] && [ "$main_ready" = "true" ] \
      && [ "$phase" = "Running" ]; then
      return 0
    fi
    sleep 5
  done
  return 1
}

check_criterion "native sidecar 'cache-warmer' has a startupProbe targeting /var/run/warmer/ready, and main container 'web' (nginx:1.27-alpine, unchanged) has started with the Pod 2/2 Running" \
  gated_app_fully_up

print_score
