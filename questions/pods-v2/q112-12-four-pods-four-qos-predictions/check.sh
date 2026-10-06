#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e` on purpose - see lib/grading.sh header comment.
set -uo pipefail

QUESTION_ID="q112-12-four-pods-four-qos-predictions${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "gold is Guaranteed with requests == limits (100m/64Mi)" \
  bash -c '
    qos="$(kubectl get pod gold -n "'"$QUESTION_ID"'" -o jsonpath="{.status.qosClass}" 2>/dev/null)"
    rcpu="$(kubectl get pod gold -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].resources.requests.cpu}" 2>/dev/null)"
    lcpu="$(kubectl get pod gold -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].resources.limits.cpu}" 2>/dev/null)"
    [ "$qos" = "Guaranteed" ] && [ "$rcpu" = "100m" ] && [ "$lcpu" = "100m" ]
  '

check_criterion "silver is Burstable, only a 50m CPU request declared" \
  bash -c '
    qos="$(kubectl get pod silver -n "'"$QUESTION_ID"'" -o jsonpath="{.status.qosClass}" 2>/dev/null)"
    rcpu="$(kubectl get pod silver -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].resources.requests.cpu}" 2>/dev/null)"
    lcpu="$(kubectl get pod silver -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].resources.limits.cpu}" 2>/dev/null)"
    [ "$qos" = "Burstable" ] && [ "$rcpu" = "50m" ] && [ -z "$lcpu" ]
  '

check_criterion "bronze is BestEffort with no resources block at all" \
  bash -c '
    qos="$(kubectl get pod bronze -n "'"$QUESTION_ID"'" -o jsonpath="{.status.qosClass}" 2>/dev/null)"
    res="$(kubectl get pod bronze -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].resources}" 2>/dev/null)"
    [ "$qos" = "BestEffort" ] && [ "$res" = "{}" ]
  '

check_criterion "tin is Guaranteed (limits-only requests get backfilled to equal limits)" \
  bash -c '
    qos="$(kubectl get pod tin -n "'"$QUESTION_ID"'" -o jsonpath="{.status.qosClass}" 2>/dev/null)"
    lcpu="$(kubectl get pod tin -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].resources.limits.cpu}" 2>/dev/null)"
    lmem="$(kubectl get pod tin -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].resources.limits.memory}" 2>/dev/null)"
    rcpu="$(kubectl get pod tin -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].resources.requests.cpu}" 2>/dev/null)"
    rmem="$(kubectl get pod tin -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].resources.requests.memory}" 2>/dev/null)"
    [ "$qos" = "Guaranteed" ] && [ "$lcpu" = "100m" ] && [ "$lmem" = "64Mi" ] && [ "$rcpu" = "$lcpu" ] && [ "$rmem" = "$lmem" ]
  '

check_criterion "All four Pods are nginx:1.27 and Running" \
  bash -c '
    for p in gold silver bronze tin; do
      img="$(kubectl get pod "$p" -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].image}" 2>/dev/null)"
      phase="$(kubectl get pod "$p" -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
      [ "$img" = "nginx:1.27" ] && [ "$phase" = "Running" ] || exit 1
    done
  '

print_score
