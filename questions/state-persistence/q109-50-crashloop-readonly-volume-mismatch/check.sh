#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q109-50-crashloop-readonly-volume-mismatch${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

is_emptydir="$(kget pod session-tracker '{.spec.volumes[?(@.name=="app-run")].emptyDir}' -n "$QUESTION_ID")"
mount_path="$(kget pod session-tracker '{.spec.containers[0].volumeMounts[?(@.name=="app-run")].mountPath}' -n "$QUESTION_ID")"
if [ -n "$is_emptydir" ] && [ "$mount_path" = "/var/run/app" ]; then
  FIXED=0
else
  FIXED=1
fi

check_criterion "Pod 'session-tracker' has an emptyDir volume 'app-run' mounted at /var/run/app" \
  [ "$FIXED" = "0" ]

check_criterion "Fix applied AND readOnlyRootFilesystem is still true, command/image unchanged" \
  bash -c "[ '$FIXED' = '0' ] && \
    [ \"\$(kubectl get pod session-tracker -n '$QUESTION_ID' -o jsonpath='{.spec.containers[0].securityContext.readOnlyRootFilesystem}')\" = 'true' ] && \
    [ \"\$(kubectl get pod session-tracker -n '$QUESTION_ID' -o jsonpath='{.spec.containers[0].image}')\" = 'busybox:1.36' ] && \
    [ \"\$(kubectl get pod session-tracker -n '$QUESTION_ID' -o jsonpath='{.spec.containers[0].command[*]}')\" = 'sh -c echo start > /var/run/app/session.pid && sleep 3600' ]"

check_criterion "Pod 'session-tracker' is stably Running with 0 restarts (not just caught mid-startup before its first crash)" \
  bash -c '
    consecutive=0
    for _ in $(seq 1 15); do
      phase="$(kubectl get pod session-tracker -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
      restarts="$(kubectl get pod session-tracker -n "'"$QUESTION_ID"'" -o jsonpath="{.status.containerStatuses[0].restartCount}" 2>/dev/null)"
      if [ "$phase" = "Running" ] && [ "$restarts" = "0" ]; then
        consecutive=$((consecutive + 1))
        [ "$consecutive" -ge 3 ] && exit 0
      else
        consecutive=0
      fi
      sleep 2
    done
    exit 1
  '

check_criterion "The app actually wrote /var/run/app/session.pid successfully" \
  bash -c "[ \"\$(kubectl exec session-tracker -n '$QUESTION_ID' -- cat /var/run/app/session.pid 2>/dev/null)\" = 'start' ]"

print_score
