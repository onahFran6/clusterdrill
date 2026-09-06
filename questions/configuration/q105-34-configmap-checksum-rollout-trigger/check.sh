#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
#
# All three criteria below are false immediately after setup.sh on their
# own (no bundling needed to satisfy the "0/N on unsolved state" gate):
#   1. the stored checksum/config annotation is for hello-v1, while
#      app-config's data is already hello-v2 - they never match until the
#      candidate recomputes and repatches the annotation.
#   2. the Deployment only owns 1 ReplicaSet until a real rollout happens.
#   3. the currently-running pods baked hello-v1 at their last startup and
#      stay that way until new pods are created by a rollout.
set -uo pipefail

QUESTION_ID="q105-34-configmap-checksum-rollout-trigger${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Recompute the checksum the same way the candidate is told to: sha256 of
# app-config's current .data via kubectl -o jsonpath.
_expected_checksum="$(kubectl get configmap app-config -n "$QUESTION_ID" -o jsonpath='{.data}' 2>/dev/null | sha256sum | awk '{print $1}')"
_actual_checksum="$(kubectl get deployment worker -n "$QUESTION_ID" \
  -o jsonpath='{.spec.template.metadata.annotations.checksum/config}' 2>/dev/null)"

check_criterion "Deployment 'worker' pod template annotation 'checksum/config' matches sha256 of app-config's current data" \
  bash -c '[ -n "$1" ] && [ "$1" = "$2" ]' _ "$_actual_checksum" "$_expected_checksum"

_rs_count="$(kubectl get rs -n "$QUESTION_ID" -l app=worker --no-headers 2>/dev/null | wc -l | tr -d ' ')"

check_criterion "Exactly one new rollout happened since setup (Deployment 'worker' owns exactly 2 ReplicaSets: the original plus one new one)" \
  [ "$_rs_count" = "2" ]

# Poll for a stable set of ready pods before reading their baked-at-startup
# file - a rollout in progress can leave old pods Terminating (still
# Running phase) and new pods still starting for a few seconds after the
# annotation patch lands.
_all_v2="false"
for _ in $(seq 1 24); do
  _ready_pods="$(kubectl get pods -n "$QUESTION_ID" -l app=worker \
    -o jsonpath='{range .items[?(@.status.phase=="Running")]}{.metadata.name}{" "}{.status.containerStatuses[0].ready}{"\n"}{end}' 2>/dev/null \
    | awk '$2=="true"{print $1}')"

  if [ -n "$_ready_pods" ]; then
    _mismatch="false"
    _count=0
    while IFS= read -r _pod; do
      [ -z "$_pod" ] && continue
      _count=$((_count + 1))
      _val="$(kubectl exec -n "$QUESTION_ID" "$_pod" -- cat /var/run/baked-greeting 2>/dev/null)"
      if [ "$_val" != "hello-v2" ]; then
        _mismatch="true"
        break
      fi
    done <<< "$_ready_pods"

    if [ "$_mismatch" = "false" ] && [ "$_count" -ge 2 ]; then
      _all_v2="true"
      break
    fi
  fi
  sleep 5
done

check_criterion "All ready 'worker' pods (2 replicas) baked GREETING=hello-v2 from a fresh container start" \
  [ "$_all_v2" = "true" ]

print_score
