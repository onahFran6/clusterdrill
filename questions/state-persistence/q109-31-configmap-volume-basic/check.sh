#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q109-31-configmap-volume-basic${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'settings-reader' exists and is Running" \
  bash -c "[ \"\$(kubectl get pod settings-reader -n '$QUESTION_ID' -o jsonpath='{.status.phase}' 2>/dev/null)\" = 'Running' ]"

check_criterion "Pod mounts ConfigMap 'app-settings' as a volume" \
  [ "$(kget pod settings-reader '{.spec.volumes[0].configMap.name}' -n "$QUESTION_ID")" = "app-settings" ]

check_criterion "ConfigMap volume mounted at /etc/app-settings" \
  [ "$(kget pod settings-reader '{.spec.containers[0].volumeMounts[0].mountPath}' -n "$QUESTION_ID")" = "/etc/app-settings" ]

check_criterion "File /etc/app-settings/mode contains 'production'" \
  bash -c "[ \"\$(kubectl exec settings-reader -n '$QUESTION_ID' -- cat /etc/app-settings/mode 2>/dev/null)\" = 'production' ]"

check_criterion "File /etc/app-settings/retries contains '3'" \
  bash -c "[ \"\$(kubectl exec settings-reader -n '$QUESTION_ID' -- cat /etc/app-settings/retries 2>/dev/null)\" = '3' ]"

print_score
