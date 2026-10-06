#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e` on purpose - see lib/grading.sh header comment.
set -uo pipefail

QUESTION_ID="q112-09-add-sidecars-to-running-pod${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'legacy' now has exactly 3 containers" \
  bash -c '
    count="$(kubectl get pod legacy -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers}" 2>/dev/null | jq "length")"
    [ "$count" = "3" ]
  '

check_criterion "access-tail/error-tail are busybox:1.36 tailing the right file" \
  bash -c '
    atail_img="$(kubectl get pod legacy -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[?(@.name==\"access-tail\")].image}" 2>/dev/null)"
    etail_img="$(kubectl get pod legacy -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[?(@.name==\"error-tail\")].image}" 2>/dev/null)"
    atail_cmd="$(kubectl get pod legacy -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[?(@.name==\"access-tail\")].command}" 2>/dev/null)"
    etail_cmd="$(kubectl get pod legacy -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[?(@.name==\"error-tail\")].command}" 2>/dev/null)"
    [ "$atail_img" = "busybox:1.36" ] && [ "$etail_img" = "busybox:1.36" ] \
      && echo "$atail_cmd" | grep -q "access.log" && echo "$etail_cmd" | grep -q "error.log"
  '

check_criterion "All three containers mount the same volume at /var/log/legacy" \
  bash -c '
    app_path="$(kubectl get pod legacy -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[?(@.name==\"app\")].volumeMounts[0].mountPath}" 2>/dev/null)"
    app_vol="$(kubectl get pod legacy -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[?(@.name==\"app\")].volumeMounts[0].name}" 2>/dev/null)"
    atail_path="$(kubectl get pod legacy -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[?(@.name==\"access-tail\")].volumeMounts[0].mountPath}" 2>/dev/null)"
    atail_vol="$(kubectl get pod legacy -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[?(@.name==\"access-tail\")].volumeMounts[0].name}" 2>/dev/null)"
    etail_path="$(kubectl get pod legacy -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[?(@.name==\"error-tail\")].volumeMounts[0].mountPath}" 2>/dev/null)"
    etail_vol="$(kubectl get pod legacy -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[?(@.name==\"error-tail\")].volumeMounts[0].name}" 2>/dev/null)"
    [ "$app_path" = "/var/log/legacy" ] && [ "$atail_path" = "/var/log/legacy" ] && [ "$etail_path" = "/var/log/legacy" ] \
      && [ "$app_vol" = "$atail_vol" ] && [ "$app_vol" = "$etail_vol" ]
  '

check_criterion "Main container 'app' keeps its original image/command, alongside the new sidecars" \
  bash -c '
    count="$(kubectl get pod legacy -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers}" 2>/dev/null | jq "length")"
    image="$(kubectl get pod legacy -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[?(@.name==\"app\")].image}" 2>/dev/null)"
    cmd="$(kubectl get pod legacy -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[?(@.name==\"app\")].command}" 2>/dev/null)"
    [ "$count" = "3" ] && [ "$image" = "busybox:1.36" ] && echo "$cmd" | grep -q "access.log"
  '

check_criterion "Pod is Running, 3/3 ready" \
  bash -c '
    for i in $(seq 1 15); do
      phase="$(kubectl get pod legacy -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
      ready="$(kubectl get pod legacy -n "'"$QUESTION_ID"'" -o jsonpath="{.status.containerStatuses[*].ready}" 2>/dev/null)"
      [ "$phase" = "Running" ] && [ "$ready" = "true true true" ] && exit 0
      sleep 2
    done
    exit 1
  '

check_criterion "error-tail is actually streaming ERR lines" \
  bash -c '
    for i in $(seq 1 6); do
      out="$(kubectl logs legacy -c error-tail -n "'"$QUESTION_ID"'" --tail=2 2>/dev/null)"
      echo "$out" | grep -q ERR && exit 0
      sleep 2
    done
    exit 1
  '

print_score
