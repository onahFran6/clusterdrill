#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q103-39-nodeaffinity-required-hostname-match${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

TARGET_NODE="$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)"

pod_running() {
  kubectl wait --for=condition=Ready pod/pinned-by-affinity -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1
}

check_criterion "Pod 'pinned-by-affinity' exists in $QUESTION_ID" \
  resource_exists pod pinned-by-affinity -n "$QUESTION_ID"

check_criterion "Pod 'pinned-by-affinity' uses image busybox:1.36 and command 'sleep 3600'" \
  bash -c '
    img="$(kubectl get pod pinned-by-affinity -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].image}" 2>/dev/null)"
    [ "$img" = "busybox:1.36" ] || exit 1
    cmd="$(kubectl get pod pinned-by-affinity -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].command}" 2>/dev/null)"
    [ "$cmd" = "[\"sleep\",\"3600\"]" ]
  '

check_criterion "Pod 'pinned-by-affinity' has a requiredDuringScheduling nodeAffinity matching kubernetes.io/hostname In ['$TARGET_NODE']" \
  bash -c '
    [ -n "'"$TARGET_NODE"'" ] || exit 1
    key="$(kubectl get pod pinned-by-affinity -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key}" 2>/dev/null)"
    [ "$key" = "kubernetes.io/hostname" ] || exit 1
    op="$(kubectl get pod pinned-by-affinity -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator}" 2>/dev/null)"
    [ "$op" = "In" ] || exit 1
    val="$(kubectl get pod pinned-by-affinity -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].values[0]}" 2>/dev/null)"
    [ "$val" = "'"$TARGET_NODE"'" ]
  '

check_criterion "Pod 'pinned-by-affinity' is Running and Ready on that exact node" \
  pod_running

print_score
