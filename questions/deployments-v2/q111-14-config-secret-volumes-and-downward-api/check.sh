#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q111-14-config-secret-volumes-and-downward-api${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "ConfigMap 'gateway-conf' is mounted at /etc/nginx/conf.d" \
  bash -c '
    vol="$(kubectl get deployment gateway -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].volumeMounts[?(@.mountPath==\"/etc/nginx/conf.d\")].name}" 2>/dev/null)"
    cm="$(kubectl get deployment gateway -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.volumes[?(@.name==\"$vol\")].configMap.name}" 2>/dev/null)"
    [ "$cm" = "gateway-conf" ]
  '

check_criterion "Secret 'gateway-key' is mounted read-only at /etc/gateway with defaultMode 0400" \
  bash -c '
    mount_ro="$(kubectl get deployment gateway -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].volumeMounts[?(@.mountPath==\"/etc/gateway\")].readOnly}" 2>/dev/null)"
    vol="$(kubectl get deployment gateway -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].volumeMounts[?(@.mountPath==\"/etc/gateway\")].name}" 2>/dev/null)"
    secret_name="$(kubectl get deployment gateway -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.volumes[?(@.name==\"$vol\")].secret.secretName}" 2>/dev/null)"
    mode="$(kubectl get deployment gateway -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.volumes[?(@.name==\"$vol\")].secret.defaultMode}" 2>/dev/null)"
    [ "$mount_ro" = "true" ] && [ "$secret_name" = "gateway-key" ] && [ "$mode" = "256" ]
  '

check_criterion "POD_NAME and NODE_NAME come from the Downward API" \
  bash -c '
    pod_field="$(kubectl get deployment gateway -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].env[?(@.name==\"POD_NAME\")].valueFrom.fieldRef.fieldPath}" 2>/dev/null)"
    node_field="$(kubectl get deployment gateway -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].env[?(@.name==\"NODE_NAME\")].valueFrom.fieldRef.fieldPath}" 2>/dev/null)"
    [ "$pod_field" = "metadata.name" ] && [ "$node_field" = "spec.nodeName" ]
  '

check_criterion "nginx actually serves 'gateway ok' from the mounted config" \
  bash -c '
    pod="$(newest_pod_name "'"$QUESTION_ID"'" app=gateway)"
    [ -n "$pod" ] || exit 1
    [ "$(kubectl exec "$pod" -n "'"$QUESTION_ID"'" -- curl -s localhost 2>/dev/null)" = "$(printf "gateway ok\n")" ]
  '

check_criterion "POD_NAME inside the container matches the pod's own name" \
  bash -c '
    pod="$(newest_pod_name "'"$QUESTION_ID"'" app=gateway)"
    [ -n "$pod" ] || exit 1
    [ "$(kubectl exec "$pod" -n "'"$QUESTION_ID"'" -- printenv POD_NAME 2>/dev/null)" = "$pod" ]
  '

check_criterion "The mounted secret file is readable only by its owner (mode 400)" \
  bash -c '
    pod="$(newest_pod_name "'"$QUESTION_ID"'" app=gateway)"
    [ -n "$pod" ] || exit 1
    [ "$(kubectl exec "$pod" -n "'"$QUESTION_ID"'" -- stat -L -c "%a" /etc/gateway/api.key 2>/dev/null)" = "400" ]
  '

print_score
