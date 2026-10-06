#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e` on purpose - see lib/grading.sh header comment.
set -uo pipefail

QUESTION_ID="q112-15-crashloop-mountpath-mismatch${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Volume mountPath is fixed to /config, with command/ConfigMap ref still unchanged" \
  bash -c '
    cmd="$(kubectl get pod calc -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].command}" 2>/dev/null)"
    cmref="$(kubectl get pod calc -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.volumes[0].configMap.name}" 2>/dev/null)"
    mountpath="$(kubectl get pod calc -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].volumeMounts[0].mountPath}" 2>/dev/null)"
    [ "$mountpath" = "/config" ] && echo "$cmd" | grep -q "cat /config/app.conf" && echo "$cmd" | grep -q "sleep 3600" && [ "$cmref" = "app-conf" ]
  '

check_criterion "Pod 'calc' is Running, 1/1, without restarting further" \
  bash -c '
    for i in $(seq 1 15); do
      phase="$(kubectl get pod calc -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
      ready="$(kubectl get pod calc -n "'"$QUESTION_ID"'" -o jsonpath="{.status.containerStatuses[0].ready}" 2>/dev/null)"
      [ "$phase" = "Running" ] && [ "$ready" = "true" ] && exit 0
      sleep 2
    done
    exit 1
  '

print_score
