#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q103-40-podaffinity-required-colocate-cache${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'replica' exists, uses image busybox:1.36 and command 'sleep 3600'" \
  bash -c '
    kubectl get pod replica -n "'"$QUESTION_ID"'" >/dev/null 2>&1 || exit 1
    img="$(kubectl get pod replica -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].image}" 2>/dev/null)"
    [ "$img" = "busybox:1.36" ] || exit 1
    cmd="$(kubectl get pod replica -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].command}" 2>/dev/null)"
    [ "$cmd" = "[\"sleep\",\"3600\"]" ]
  '

check_criterion "Pod 'replica' has a requiredDuringScheduling podAffinity rule matching role=primary, topologyKey kubernetes.io/hostname" \
  bash -c '
    sel="$(kubectl get pod replica -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.affinity.podAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].labelSelector.matchLabels.role}" 2>/dev/null)"
    [ "$sel" = "primary" ] || exit 1
    topo="$(kubectl get pod replica -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.affinity.podAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].topologyKey}" 2>/dev/null)"
    [ "$topo" = "kubernetes.io/hostname" ]
  '

# Bundles "primary is still Running/labeled, untouched" together with
# replica's own Running/colocated state - primary alone being untouched is
# already true immediately after setup.sh, before the candidate does
# anything, so as a standalone criterion it would trivially pass pre-solve.
check_criterion "Pod 'primary' remains untouched (Running, role=primary) and 'replica' is Running/Ready and colocated with it on the same node" \
  bash -c '
    [ "$(kubectl get pod primary -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)" = "Running" ] || exit 1
    [ "$(kubectl get pod primary -n "'"$QUESTION_ID"'" -o jsonpath="{.metadata.labels.role}" 2>/dev/null)" = "primary" ] || exit 1
    kubectl wait --for=condition=Ready pod/replica -n "'"$QUESTION_ID"'" --timeout=60s >/dev/null 2>&1 || exit 1
    p="$(kubectl get pod primary -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.nodeName}" 2>/dev/null)"
    r="$(kubectl get pod replica -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.nodeName}" 2>/dev/null)"
    [ -n "$p" ] && [ "$p" = "$r" ]
  '

print_score
