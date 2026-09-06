#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-46-configmap-missing-mount-pending${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "ConfigMap 'settings-config' exists with key MODE=production" \
  [ "$(kubectl get configmap settings-config -n "$QUESTION_ID" -o jsonpath='{.data.MODE}' 2>/dev/null)" = "production" ]

check_criterion "Deployment 'report-generator' has 1/1 ready replicas" \
  bash -c '
    ready="$(kubectl get deployment report-generator -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    [ "$ready" = "1" ]
  '

check_criterion "Running pod actually mounts settings-config (file /etc/report-settings/MODE = production) AND the Deployment's own volume reference was left untouched" \
  bash -c '
    pod="$(kubectl get pods -n "'"$QUESTION_ID"'" -l app=report-generator -o jsonpath="{.items[0].metadata.name}" 2>/dev/null)"
    [ -n "$pod" ] || exit 1
    content="$(kubectl exec -n "'"$QUESTION_ID"'" "$pod" -- cat /etc/report-settings/MODE 2>/dev/null)"
    [ "$content" = "production" ] || exit 1
    ref="$(kubectl get deployment report-generator -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.volumes[?(@.configMap.name==\"settings-config\")].configMap.name}" 2>/dev/null)"
    [ "$ref" = "settings-config" ]
  '

print_score
