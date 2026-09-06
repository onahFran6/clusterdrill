#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-02-configmap-from-file-volume${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "ConfigMap 'nginx-conf' exists" \
  resource_exists configmap nginx-conf -n "$QUESTION_ID"

check_criterion "ConfigMap 'nginx-conf' has key q105-02-nginx.conf" \
  [ -n "$(kget configmap 'nginx-conf' '{.data.q105-02-nginx\.conf}' -n "$QUESTION_ID")" ]

check_criterion "ConfigMap key content mentions 'q105-02 ok'" \
  bash -c "kubectl get configmap nginx-conf -n '$QUESTION_ID' -o jsonpath='{.data.q105-02-nginx\.conf}' 2>/dev/null | grep -q 'q105-02 ok'"

check_criterion "Pod 'web-server' mounts a volume backed by ConfigMap nginx-conf" \
  bash -c "kubectl get pod web-server -n '$QUESTION_ID' -o json 2>/dev/null | grep -q '\"nginx-conf\"'"

check_criterion "Pod 'web-server' mounts that volume at /etc/nginx/conf.d" \
  [ "$(kget pod web-server '{.spec.containers[0].volumeMounts[0].mountPath}' -n "$QUESTION_ID")" = "/etc/nginx/conf.d" ]

check_criterion "File is actually present in the container at /etc/nginx/conf.d/q105-02-nginx.conf" \
  bash -c "kubectl exec -n '$QUESTION_ID' web-server -- cat /etc/nginx/conf.d/q105-02-nginx.conf 2>/dev/null | grep -q 'q105-02 ok'"

print_score
