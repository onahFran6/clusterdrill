#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q107-13-debug-node-shell${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

DEBUG_POD="$(kubectl get pods -n "$QUESTION_ID" -o name 2>/dev/null | grep 'node-debugger-' | head -1)"
DEBUG_POD="${DEBUG_POD#pod/}"

check_criterion "A 'node-debugger-*' pod exists in $QUESTION_ID" \
  [ -n "$DEBUG_POD" ]

node_name="$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)"
pod_node="$(kget pod "$DEBUG_POD" '{.spec.nodeName}' -n "$QUESTION_ID")"

check_criterion "Debug pod is scheduled on the cluster's node" \
  bash -c "[ -n '$DEBUG_POD' ] && [ '$pod_node' = '$node_name' ]"

check_criterion "Debug pod uses image busybox:1.36" \
  [ "$(kget pod "$DEBUG_POD" '{.spec.containers[0].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

mount_paths="$(kget pod "$DEBUG_POD" '{.spec.containers[0].volumeMounts[*].mountPath}' -n "$QUESTION_ID")"

check_criterion "Debug pod mounts the host filesystem at /host" \
  bash -c "case ' $mount_paths ' in *' /host '*) exit 0;; *) exit 1;; esac"

print_score
