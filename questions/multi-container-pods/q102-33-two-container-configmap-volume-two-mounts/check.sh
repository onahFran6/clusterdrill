#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-33-two-container-configmap-volume-two-mounts${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'settings-readers' has exactly 2 containers" \
  [ "$(kget pod settings-readers '{.spec.containers[*].name}' -n "$QUESTION_ID" | wc -w | tr -d ' ')" = "2" ]

check_criterion "'primary' container mounts a configMap volume at /etc/primary-settings" \
  [ "$(kget pod settings-readers '{.spec.containers[?(@.name=="primary")].volumeMounts[?(@.mountPath=="/etc/primary-settings")].name}' -n "$QUESTION_ID")" != "" ]

check_criterion "'secondary' container mounts a configMap volume at /etc/secondary-settings" \
  [ "$(kget pod settings-readers '{.spec.containers[?(@.name=="secondary")].volumeMounts[?(@.mountPath=="/etc/secondary-settings")].name}' -n "$QUESTION_ID")" != "" ]

check_criterion "Pod's volume(s) reference ConfigMap 'shared-settings'" \
  bash -c "kubectl get pod settings-readers -n '$QUESTION_ID' -o jsonpath='{.spec.volumes[*].configMap.name}' | grep -qw shared-settings"

CONTENT_OK=0
for _ in $(seq 1 12); do
  PRIMARY_CONTENT="$(kubectl exec settings-readers -c primary -n "$QUESTION_ID" -- cat /etc/primary-settings/mode.conf 2>/dev/null)"
  SECONDARY_CONTENT="$(kubectl exec settings-readers -c secondary -n "$QUESTION_ID" -- cat /etc/secondary-settings/mode.conf 2>/dev/null)"
  if [ "$PRIMARY_CONTENT" = "region=eu-west-1" ] && [ "$SECONDARY_CONTENT" = "region=eu-west-1" ]; then
    CONTENT_OK=1
    break
  fi
  sleep 3
done
check_criterion "both containers read the identical ConfigMap content ('region=eu-west-1') at their own mount path" \
  [ "$CONTENT_OK" = "1" ]

print_score
