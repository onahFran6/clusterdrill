#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-48-limitrange-type-pod-aggregate${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'multi-app' has 2/2 ready containers AND LimitRange 'pod-aggregate-limits' still has type Pod, max cpu=500m, max memory=512Mi (unchanged)" \
  bash -c '
    ready_count="$(kubectl get pod multi-app -n "'"$QUESTION_ID"'" -o jsonpath="{range .status.containerStatuses[*]}{.ready}{\"\n\"}{end}" 2>/dev/null | grep -c true)"
    total_count="$(kubectl get pod multi-app -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[*].name}" 2>/dev/null | wc -w | tr -d " ")"
    [ "$ready_count" = "2" ] && [ "$total_count" = "2" ] || exit 1
    typ="$(kubectl get limitrange pod-aggregate-limits -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.limits[0].type}" 2>/dev/null)"
    [ "$typ" = "Pod" ] || exit 1
    cpu="$(kubectl get limitrange pod-aggregate-limits -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.limits[0].max.cpu}" 2>/dev/null)"
    [ "$cpu" = "500m" ] || exit 1
    mem="$(kubectl get limitrange pod-aggregate-limits -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.limits[0].max.memory}" 2>/dev/null)"
    [ "$mem" = "512Mi" ]
  '

check_criterion "Sum of both containers' CPU limits is at most 500m" \
  bash -c '
    cpu_list="$(kubectl get pod multi-app -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[*].resources.limits.cpu}" 2>/dev/null)"
    [ -n "$cpu_list" ] || exit 1
    total=0
    for cpu in $cpu_list; do
      millis="${cpu%m}"
      if [ "$millis" = "$cpu" ]; then
        millis=$(awk -v v="$cpu" "BEGIN { printf \"%d\", v*1000 }")
      fi
      total=$((total + millis))
    done
    [ "$total" -le 500 ]
  '

check_criterion "Sum of both containers' memory limits is at most 512Mi" \
  bash -c '
    mem_list="$(kubectl get pod multi-app -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[*].resources.limits.memory}" 2>/dev/null)"
    [ -n "$mem_list" ] || exit 1
    total=0
    for mem in $mem_list; do
      case "$mem" in
        *Mi) mebi="${mem%Mi}" ;;
        *Gi) mebi=$(awk -v v="${mem%Gi}" "BEGIN { printf \"%d\", v*1024 }") ;;
        *) exit 1 ;;
      esac
      total=$((total + mebi))
    done
    [ "$total" -le 512 ]
  '

print_score
