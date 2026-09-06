#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q101-49-rollout-restart-stale-secret-values${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

running_pod_sees_rotated_token() {
  local i pod val secret_value secret_name secret_key literal_value restarted_at
  for ((i = 0; i < 30; i++)); do
    secret_value="$(kubectl get secret billing-creds -n "$QUESTION_ID" -o jsonpath='{.data.API_TOKEN}' 2>/dev/null | base64 -d 2>/dev/null)"
    secret_name="$(kget deployment billing-sync '{.spec.template.spec.containers[0].env[?(@.name=="API_TOKEN")].valueFrom.secretKeyRef.name}' -n "$QUESTION_ID")"
    secret_key="$(kget deployment billing-sync '{.spec.template.spec.containers[0].env[?(@.name=="API_TOKEN")].valueFrom.secretKeyRef.key}' -n "$QUESTION_ID")"
    literal_value="$(kget deployment billing-sync '{.spec.template.spec.containers[0].env[?(@.name=="API_TOKEN")].value}' -n "$QUESTION_ID")"
    restarted_at="$(kget deployment billing-sync '{.spec.template.metadata.annotations.kubectl\.kubernetes\.io/restartedAt}' -n "$QUESTION_ID")"
    pod="$(kubectl get pods -n "$QUESTION_ID" -l app=billing-sync --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)"
    if [ -n "$pod" ]; then
      val="$(kubectl exec -n "$QUESTION_ID" "$pod" -- sh -c 'echo $API_TOKEN' 2>/dev/null)"
      if [ "$secret_value" = "rotated-token-value" ] \
        && [ "$secret_name" = "billing-creds" ] \
        && [ "$secret_key" = "API_TOKEN" ] \
        && [ -z "$literal_value" ] \
        && [ -n "$restarted_at" ] \
        && [ "$val" = "$secret_value" ]; then
        return 0
      fi
    fi
    sleep 2
  done
  return 1
}
check_criterion "Rollout restart preserves secretKeyRef and the new pod reads the rotated Secret value" \
  running_pod_sees_rotated_token

print_score
