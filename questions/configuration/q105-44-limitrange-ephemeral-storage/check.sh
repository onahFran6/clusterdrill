#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-44-limitrange-ephemeral-storage${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "LimitRange 'storage-limits' has the correct Container ephemeral-storage default/defaultRequest/min/max" \
  bash -c '
    jp() { kubectl get limitrange storage-limits -n "'"$QUESTION_ID"'" -o jsonpath="$1" 2>/dev/null; }
    typ="$(jp "{.spec.limits[?(@.default.ephemeral-storage)].type}")"
    [ "$typ" = "Container" ] || exit 1
    def="$(jp "{.spec.limits[?(@.default.ephemeral-storage)].default.ephemeral-storage}")"
    [ "$def" = "500Mi" ] || exit 1
    defreq="$(jp "{.spec.limits[?(@.default.ephemeral-storage)].defaultRequest.ephemeral-storage}")"
    [ "$defreq" = "100Mi" ] || exit 1
    min="$(jp "{.spec.limits[?(@.default.ephemeral-storage)].min.ephemeral-storage}")"
    [ "$min" = "50Mi" ] || exit 1
    max="$(jp "{.spec.limits[?(@.default.ephemeral-storage)].max.ephemeral-storage}")"
    [ "$max" = "1Gi" ]
  '

check_criterion "Pod 'scratch-worker' is Running" \
  bash -c '
    phase="$(kubectl get pod scratch-worker -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
    [ "$phase" = "Running" ]
  '

check_criterion "Pod 'scratch-worker' picked up the LimitRange's ephemeral-storage request (100Mi)" \
  [ "$(kget pod scratch-worker '{.spec.containers[0].resources.requests.ephemeral-storage}' -n "$QUESTION_ID")" = "100Mi" ]

check_criterion "Pod 'scratch-worker' picked up the LimitRange's ephemeral-storage limit (500Mi)" \
  [ "$(kget pod scratch-worker '{.spec.containers[0].resources.limits.ephemeral-storage}' -n "$QUESTION_ID")" = "500Mi" ]

print_score
