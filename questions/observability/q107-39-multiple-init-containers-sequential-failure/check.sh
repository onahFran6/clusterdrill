#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q107-39-multiple-init-containers-sequential-failure${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "All 3 init containers (create-workdir, fetch-config, validate-config) completed successfully" \
  bash -c '
    for c in create-workdir fetch-config validate-config; do
      reason="$(kubectl get pod report-builder -n "'"$QUESTION_ID"'" -o jsonpath="{.status.initContainerStatuses[?(@.name==\"$c\")].state.terminated.reason}" 2>/dev/null)"
      [ "$reason" = "Completed" ] || exit 1
    done
  '

check_criterion "Pod 'report-builder' main container is Running and Ready, image unchanged" \
  bash -c '
    phase="$(kubectl get pod report-builder -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
    [ "$phase" = "Running" ] || exit 1
    ready="$(kubectl get pod report-builder -n "'"$QUESTION_ID"'" -o jsonpath="{.status.containerStatuses[0].ready}" 2>/dev/null)"
    [ "$ready" = "true" ] || exit 1
    image="$(kubectl get pod report-builder -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].image}" 2>/dev/null)"
    [ "$image" = "nginx:1.25-alpine" ]
  '

print_score
