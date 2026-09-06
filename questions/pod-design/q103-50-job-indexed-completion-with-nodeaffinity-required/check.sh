#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q103-50-job-indexed-completion-with-nodeaffinity-required${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

TARGET_NODE="$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)"

job_completed() {
  kubectl wait --for=condition=Complete job/sharded-worker -n "$QUESTION_ID" --timeout=90s >/dev/null 2>&1 || return 1
  [ "$(kget job sharded-worker '{.status.succeeded}' -n "$QUESTION_ID")" = "3" ]
}

check_criterion "Job 'sharded-worker' exists in $QUESTION_ID" \
  resource_exists job sharded-worker -n "$QUESTION_ID"

check_criterion "Job 'sharded-worker' has completionMode Indexed, completions=3, parallelism=3" \
  bash -c '
    NS="'"$QUESTION_ID"'"
    mode="$(kubectl get job sharded-worker -n "$NS" -o jsonpath="{.spec.completionMode}" 2>/dev/null)"
    [ "$mode" = "Indexed" ] || exit 1
    c="$(kubectl get job sharded-worker -n "$NS" -o jsonpath="{.spec.completions}" 2>/dev/null)"
    [ "$c" = "3" ] || exit 1
    p="$(kubectl get job sharded-worker -n "$NS" -o jsonpath="{.spec.parallelism}" 2>/dev/null)"
    [ "$p" = "3" ]
  '

check_criterion "Job 'sharded-worker' pod template has a requiredDuringScheduling nodeAffinity matching kubernetes.io/hostname In ['$TARGET_NODE']" \
  bash -c '
    NS="'"$QUESTION_ID"'"
    [ -n "'"$TARGET_NODE"'" ] || exit 1
    key="$(kubectl get job sharded-worker -n "$NS" -o jsonpath="{.spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key}" 2>/dev/null)"
    [ "$key" = "kubernetes.io/hostname" ] || exit 1
    val="$(kubectl get job sharded-worker -n "$NS" -o jsonpath="{.spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].values[0]}" 2>/dev/null)"
    [ "$val" = "'"$TARGET_NODE"'" ]
  '

check_criterion "Job 'sharded-worker' keeps image busybox:1.36" \
  [ "$(kget job sharded-worker '{.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

check_criterion "Job 'sharded-worker' completed all 3 indexed pods successfully" \
  job_completed

print_score
