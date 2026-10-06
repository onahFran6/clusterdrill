#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e` on purpose - see lib/grading.sh header comment.
set -uo pipefail

QUESTION_ID="q115-01-docker-run-to-pod-yaml${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'cache' uses the exact image, restartPolicy and containerPort" \
  bash -c '
    img="$(kubectl get pod cache -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].image}" 2>/dev/null)"
    restart="$(kubectl get pod cache -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.restartPolicy}" 2>/dev/null)"
    port="$(kubectl get pod cache -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].ports[0].containerPort}" 2>/dev/null)"
    [ "$img" = "nginxinc/nginx-unprivileged:1.27-alpine" ] && [ "$restart" = "Always" ] && [ "$port" = "8080" ]
  '

check_criterion "Pod-level securityContext.runAsUser is 101" \
  bash -c '[ "$(kubectl get pod cache -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.securityContext.runAsUser}" 2>/dev/null)" = "101" ]'

check_criterion "resources.limits == {cpu: 500m, memory: 128Mi}" \
  bash -c '
    cpu="$(kubectl get pod cache -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].resources.limits.cpu}" 2>/dev/null)"
    mem="$(kubectl get pod cache -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].resources.limits.memory}" 2>/dev/null)"
    [ "$cpu" = "500m" ] && [ "$mem" = "128Mi" ]
  '

check_criterion "Env MODE=fast and MAX_ITEMS=\"64\" (string) are both set" \
  bash -c '
    mode="$(kubectl get pod cache -n "'"$QUESTION_ID"'" -o json 2>/dev/null | jq -r "[.spec.containers[0].env[]? | select(.name==\"MODE\") | .value][0]")"
    items="$(kubectl get pod cache -n "'"$QUESTION_ID"'" -o json 2>/dev/null | jq -r "[.spec.containers[0].env[]? | select(.name==\"MAX_ITEMS\") | .value][0]")"
    [ "$mode" = "fast" ] && [ "$items" = "64" ]
  '

check_criterion "An emptyDir volume is mounted at /data" \
  bash -c '
    vol="$(kubectl get pod cache -n "'"$QUESTION_ID"'" -o json 2>/dev/null | jq -r "
      .spec.volumes[]? | select(.emptyDir != null) | .name")"
    [ -z "$vol" ] && exit 1
    mount="$(kubectl get pod cache -n "'"$QUESTION_ID"'" -o json 2>/dev/null | jq -r --arg v "$vol" "
      [.spec.containers[0].volumeMounts[]? | select(.name==\$v) | .mountPath][0]")"
    [ "$mount" = "/data" ]
  '

check_criterion "Pod 'cache' is Running" \
  bash -c '[ "$(kubectl get pod cache -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)" = "Running" ]'

check_criterion "exec -- id shows uid=101" \
  bash -c 'kubectl exec cache -n "'"$QUESTION_ID"'" -- id 2>/dev/null | grep -q "uid=101"'

check_criterion "exec -- printenv MODE MAX_ITEMS shows both values" \
  bash -c '
    out="$(kubectl exec cache -n "'"$QUESTION_ID"'" -- printenv MODE MAX_ITEMS 2>/dev/null)"
    echo "$out" | grep -qx "fast" && echo "$out" | grep -qx "64"
  '

print_score
