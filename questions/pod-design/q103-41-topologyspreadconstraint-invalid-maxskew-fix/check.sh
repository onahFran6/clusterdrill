#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q103-41-topologyspreadconstraint-invalid-maxskew-fix${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

pod_running() {
  kubectl wait --for=condition=Ready pod/spread-worker -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1
}

check_criterion "Pod 'spread-worker' exists in $QUESTION_ID" \
  resource_exists pod spread-worker -n "$QUESTION_ID"

check_criterion "Pod 'spread-worker' uses image busybox:1.36 and command 'sleep 3600'" \
  bash -c '
    img="$(kubectl get pod spread-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].image}" 2>/dev/null)"
    [ "$img" = "busybox:1.36" ] || exit 1
    cmd="$(kubectl get pod spread-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].command}" 2>/dev/null)"
    [ "$cmd" = "[\"sleep\",\"3600\"]" ]
  '

check_criterion "Pod 'spread-worker' has maxSkew=1, topologyKey=kubernetes.io/hostname, whenUnsatisfiable=DoNotSchedule, labelSelector app=spread-worker" \
  bash -c '
    tsc="$(kubectl get pod spread-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.topologySpreadConstraints[0].maxSkew}" 2>/dev/null)"
    [ "$tsc" = "1" ] || exit 1
    topo="$(kubectl get pod spread-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.topologySpreadConstraints[0].topologyKey}" 2>/dev/null)"
    [ "$topo" = "kubernetes.io/hostname" ] || exit 1
    when="$(kubectl get pod spread-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.topologySpreadConstraints[0].whenUnsatisfiable}" 2>/dev/null)"
    [ "$when" = "DoNotSchedule" ] || exit 1
    sel="$(kubectl get pod spread-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.topologySpreadConstraints[0].labelSelector.matchLabels.app}" 2>/dev/null)"
    [ "$sel" = "spread-worker" ]
  '

check_criterion "Pod 'spread-worker' is Running and Ready" \
  pod_running

print_score
