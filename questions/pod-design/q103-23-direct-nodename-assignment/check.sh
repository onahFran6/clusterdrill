#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q103-23-direct-nodename-assignment${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# The manifest setup.sh seeds is never applied, so the unsolved state has NO
# pod object at all - every criterion below is genuinely 0 until the
# candidate both fills in nodeName and applies the manifest, even though
# this cluster is single-node.
TARGET_NODE="$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)"

pod_running() {
  kubectl wait --for=condition=Ready pod/node-pinned -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1
}

check_criterion "Pod 'node-pinned' exists in $QUESTION_ID" \
  resource_exists pod node-pinned -n "$QUESTION_ID"

check_criterion "Pod 'node-pinned' uses image busybox:1.36" \
  [ "$(kget pod node-pinned '{.spec.containers[0].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

check_criterion "Pod 'node-pinned' keeps command 'sleep 3600'" \
  [ "$(kget pod node-pinned '{.spec.containers[0].command}' -n "$QUESTION_ID")" = '["sleep","3600"]' ]

check_criterion "Pod 'node-pinned' has spec.nodeName set directly to this cluster's node ('$TARGET_NODE')" \
  bash -c "[ -n '$TARGET_NODE' ] && [ '$(kget pod node-pinned '{.spec.nodeName}' -n "$QUESTION_ID")' = '$TARGET_NODE' ]"

check_criterion "Pod 'node-pinned' is Running and Ready on that exact node" \
  pod_running

print_score
