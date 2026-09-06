#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q103-47-combined-nodeaffinity-podantiaffinity-manifest${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

pod_running() {
  kubectl wait --for=condition=Ready pod/constrained-worker -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1
}

check_criterion "Pod 'constrained-worker' exists in $QUESTION_ID" \
  resource_exists pod constrained-worker -n "$QUESTION_ID"

check_criterion "Pod 'constrained-worker' uses image busybox:1.36 and command 'sleep 3600'" \
  bash -c '
    img="$(kubectl get pod constrained-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].image}" 2>/dev/null)"
    [ "$img" = "busybox:1.36" ] || exit 1
    cmd="$(kubectl get pod constrained-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].command}" 2>/dev/null)"
    [ "$cmd" = "[\"sleep\",\"3600\"]" ]
  '

check_criterion "Pod 'constrained-worker' has a requiredDuringScheduling nodeAffinity matching kubernetes.io/os In [linux]" \
  bash -c '
    NS="'"$QUESTION_ID"'"
    key="$(kubectl get pod constrained-worker -n "$NS" -o jsonpath="{.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key}" 2>/dev/null)"
    [ "$key" = "kubernetes.io/os" ] || exit 1
    op="$(kubectl get pod constrained-worker -n "$NS" -o jsonpath="{.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator}" 2>/dev/null)"
    [ "$op" = "In" ] || exit 1
    val="$(kubectl get pod constrained-worker -n "$NS" -o jsonpath="{.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].values[0]}" 2>/dev/null)"
    [ "$val" = "linux" ]
  '

check_criterion "Pod 'constrained-worker' has a requiredDuringScheduling podAntiAffinity matching app=legacy-worker, topologyKey kubernetes.io/hostname" \
  bash -c '
    NS="'"$QUESTION_ID"'"
    sel="$(kubectl get pod constrained-worker -n "$NS" -o jsonpath="{.spec.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].labelSelector.matchLabels.app}" 2>/dev/null)"
    [ "$sel" = "legacy-worker" ] || exit 1
    topo="$(kubectl get pod constrained-worker -n "$NS" -o jsonpath="{.spec.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].topologyKey}" 2>/dev/null)"
    [ "$topo" = "kubernetes.io/hostname" ]
  '

check_criterion "Pod 'constrained-worker' is Running and Ready with both requirements satisfied" \
  pod_running

print_score
