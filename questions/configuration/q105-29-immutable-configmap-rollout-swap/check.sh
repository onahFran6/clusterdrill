#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
#
# Note on ordering: "app-config-v1 is untouched" is true the instant
# setup.sh finishes, before the candidate does anything - graded alone it
# would violate the "unsolved state scores 0" gate. It's folded into the
# same criterion as "app-config-v2 exists with the right shape", which is
# only true once the candidate has actually created the replacement, so
# nothing scores here until real work has happened.
set -uo pipefail

QUESTION_ID="q105-29-immutable-configmap-rollout-swap${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

_v1_immutable="$(kget configmap app-config-v1 '{.immutable}' -n "$QUESTION_ID")"
_v1_loglevel="$(kget configmap app-config-v1 '{.data.LOG_LEVEL}' -n "$QUESTION_ID")"
_v2_immutable="$(kget configmap app-config-v2 '{.immutable}' -n "$QUESTION_ID")"
_v2_loglevel="$(kget configmap app-config-v2 '{.data.LOG_LEVEL}' -n "$QUESTION_ID")"

check_criterion "app-config-v1 is untouched (still immutable, still LOG_LEVEL=info) and app-config-v2 exists, immutable, with LOG_LEVEL=debug" \
  bash -c '[ "$1" = "true" ] && [ "$2" = "info" ] && [ "$3" = "true" ] && [ "$4" = "debug" ]' _ \
  "$_v1_immutable" "$_v1_loglevel" "$_v2_immutable" "$_v2_loglevel"

_worker_volume_cm="$(kubectl get deployment worker -n "$QUESTION_ID" \
  -o jsonpath='{.spec.template.spec.volumes[?(@.name=="app-config")].configMap.name}' 2>/dev/null)"

check_criterion "Deployment 'worker' pod template volume 'app-config' references app-config-v2" \
  [ "$_worker_volume_cm" = "app-config-v2" ]

# Poll for a stable set of ready pods before reading their mounted file -
# a rollout in progress can leave old pods Terminating and new pods still
# starting for a few seconds after a patch/restart is issued.
_all_debug="false"
for _ in $(seq 1 24); do
  _ready_pods="$(kubectl get pods -n "$QUESTION_ID" -l app=worker \
    -o jsonpath='{range .items[?(@.status.phase=="Running")]}{.metadata.name}{" "}{.status.containerStatuses[0].ready}{"\n"}{end}' 2>/dev/null \
    | awk '$2=="true"{print $1}')"

  if [ -n "$_ready_pods" ]; then
    _mismatch="false"
    while IFS= read -r _pod; do
      [ -z "$_pod" ] && continue
      _val="$(kubectl exec -n "$QUESTION_ID" "$_pod" -- cat /etc/app/LOG_LEVEL 2>/dev/null)"
      if [ "$_val" != "debug" ]; then
        _mismatch="true"
        break
      fi
    done <<< "$_ready_pods"

    if [ "$_mismatch" = "false" ]; then
      _all_debug="true"
      break
    fi
  fi
  sleep 5
done

check_criterion "All ready 'worker' pods have /etc/app/LOG_LEVEL containing 'debug'" \
  [ "$_all_debug" = "true" ]

print_score
