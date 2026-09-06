#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q103-44-nodeaffinity-preferred-weighted-fallback${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

pod_running() {
  kubectl wait --for=condition=Ready pod/flexible-worker -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1
}

check_criterion "Pod 'flexible-worker' exists in $QUESTION_ID" \
  resource_exists pod flexible-worker -n "$QUESTION_ID"

check_criterion "Pod 'flexible-worker' uses image busybox:1.36 and command 'sleep 3600'" \
  bash -c '
    img="$(kubectl get pod flexible-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].image}" 2>/dev/null)"
    [ "$img" = "busybox:1.36" ] || exit 1
    cmd="$(kubectl get pod flexible-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].command}" 2>/dev/null)"
    [ "$cmd" = "[\"sleep\",\"3600\"]" ]
  '

check_criterion "Pod 'flexible-worker' has 2 preferred nodeAffinity terms: weight 80 os=linux, weight 20 arch=arm64" \
  bash -c '
    NS="'"$QUESTION_ID"'"
    w1="$(kubectl get pod flexible-worker -n "$NS" -o jsonpath="{.spec.affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].weight}" 2>/dev/null)"
    k1="$(kubectl get pod flexible-worker -n "$NS" -o jsonpath="{.spec.affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].preference.matchExpressions[0].key}" 2>/dev/null)"
    v1="$(kubectl get pod flexible-worker -n "$NS" -o jsonpath="{.spec.affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].preference.matchExpressions[0].values[0]}" 2>/dev/null)"
    [ "$w1" = "80" ] && [ "$k1" = "kubernetes.io/os" ] && [ "$v1" = "linux" ] || exit 1
    w2="$(kubectl get pod flexible-worker -n "$NS" -o jsonpath="{.spec.affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[1].weight}" 2>/dev/null)"
    k2="$(kubectl get pod flexible-worker -n "$NS" -o jsonpath="{.spec.affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[1].preference.matchExpressions[0].key}" 2>/dev/null)"
    v2="$(kubectl get pod flexible-worker -n "$NS" -o jsonpath="{.spec.affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution[1].preference.matchExpressions[0].values[0]}" 2>/dev/null)"
    [ "$w2" = "20" ] && [ "$k2" = "kubernetes.io/arch" ] && [ "$v2" = "arm64" ]
  '

check_criterion "Pod 'flexible-worker' is Running and Ready" \
  pod_running

print_score
