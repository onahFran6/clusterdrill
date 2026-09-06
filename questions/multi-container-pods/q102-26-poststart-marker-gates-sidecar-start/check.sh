#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-26-poststart-marker-gates-sidecar-start${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# A just-deleted-and-recreated pod can sit Terminating with .status.phase
# still Running for a few seconds, and postStart itself takes ~2s to fire -
# poll for a stable Running 2/2 snapshot instead of trusting one read.
POD_STABLE=0
for _ in $(seq 1 24); do
  PHASE="$(kget pod staged-app '{.status.phase}' -n "$QUESTION_ID")"
  READY_COUNT="$(kget pod staged-app '{.status.containerStatuses[*].ready}' -n "$QUESTION_ID" | tr ' ' '\n' | grep -c '^true$')"
  if [ "$PHASE" = "Running" ] && [ "$READY_COUNT" = "2" ]; then
    POD_STABLE=1
    break
  fi
  sleep 5
done

APP_IMAGE="$(kget pod staged-app '{.spec.containers[?(@.name=="app")].image}' -n "$QUESTION_ID")"
TAILER_IMAGE="$(kget pod staged-app '{.spec.containers[?(@.name=="log-tailer")].image}' -n "$QUESTION_ID")"
POSTSTART_CMD="$(kget pod staged-app '{.spec.containers[?(@.name=="app")].lifecycle.postStart.exec.command}' -n "$QUESTION_ID")"

# 'staged-app' being Running 2/2 with both container names/images unchanged
# is already true right after setup.sh (the pod never crashes - "app"'s
# broken postStart hook exits 0, and "log-tailer" just loops silently
# waiting for a marker that never arrives at /shared/ready). Bundle that
# with the actual fix - the postStart hook referencing the real shared
# mount path, /shared/ready, instead of the broken /tmp/ready - into one
# criterion so nothing scores until the candidate corrects it.
check_criterion "Pod 'staged-app' Running 2/2 (app/log-tailer unchanged) with postStart writing the marker to /shared/ready" \
  bash -c "[ '$POD_STABLE' = '1' ] && [ '$APP_IMAGE' = 'busybox:1.36' ] && [ '$TAILER_IMAGE' = 'busybox:1.36' ] && echo '$POSTSTART_CMD' | grep -q '/shared/ready'"

# The definitive live-behavior proof: log-tailer only touches this file
# after it exits its wait loop, which only happens once /shared/ready
# genuinely exists on the shared volume - false in the unsolved state (the
# loop runs forever) and only true once postStart is fixed and the pod is
# recreated so the hook actually fires.
check_criterion "exec into 'log-tailer' can cat /shared/log-tailer-active (sidecar proceeded past its wait loop)" \
  kubectl exec staged-app -c log-tailer -n "$QUESTION_ID" -- cat /shared/log-tailer-active

print_score
