#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-28-shared-pid-namespace-signal-container${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# setup.sh already leaves the Pod Running 2/2 with the right names/images -
# only spec.shareProcessNamespace differs between the broken and fixed
# state, so bundle all of that into ONE criterion with the field that
# actually changes, or this would score non-zero before any fix lands.
POD_PHASE="$(kget pod config-reload-app '{.status.phase}' -n "$QUESTION_ID")"
READY_COUNT="$(kget pod config-reload-app '{.status.containerStatuses[*].ready}' -n "$QUESTION_ID" | tr ' ' '\n' | grep -c '^true$')"
CONTAINER_COUNT="$(kget pod config-reload-app '{.spec.containers[*].name}' -n "$QUESTION_ID" | wc -w | tr -d ' ')"
MAIN_IMAGE="$(kget pod config-reload-app '{.spec.containers[?(@.name=="main")].image}' -n "$QUESTION_ID")"
WATCHER_IMAGE="$(kget pod config-reload-app '{.spec.containers[?(@.name=="watcher")].image}' -n "$QUESTION_ID")"
SHARE_PID="$(kget pod config-reload-app '{.spec.shareProcessNamespace}' -n "$QUESTION_ID")"

check_criterion "Pod 'config-reload-app' Running 2/2 (main+watcher, busybox:1.36) with shareProcessNamespace true" \
  bash -c "[ '$POD_PHASE' = 'Running' ] && [ '$READY_COUNT' = '2' ] && [ '$CONTAINER_COUNT' = '2' ] && [ '$MAIN_IMAGE' = 'busybox:1.36' ] && [ '$WATCHER_IMAGE' = 'busybox:1.36' ] && [ '$SHARE_PID' = 'true' ]"

# The real proof this works end-to-end: watcher found main's live PID via
# ps in the shared namespace and actually signaled it, so main's SIGHUP
# trap fired and wrote at least one line to its own /tmp/main-reload.log.
# This is naturally empty/absent in the unsolved state (each container has
# its own isolated PID namespace, so watcher's ps only ever sees itself).
check_criterion "'watcher' actually signaled 'main' - /tmp/main-reload.log has a reload line" \
  kubectl exec config-reload-app -c main -n "$QUESTION_ID" -- sh -c "test -s /tmp/main-reload.log && grep -q reload- /tmp/main-reload.log"

print_score
