#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-06-secret-tls-volume-mount${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Secret 'edge-tls' exists" \
  resource_exists secret edge-tls -n "$QUESTION_ID"

check_criterion "Secret 'edge-tls' is of type kubernetes.io/tls" \
  [ "$(kget secret edge-tls '{.type}' -n "$QUESTION_ID")" = "kubernetes.io/tls" ]

check_criterion "Secret 'edge-tls' has both tls.crt and tls.key data keys" \
  bash -c '[ -n "$(kubectl get secret edge-tls -n '"$QUESTION_ID"' -o jsonpath="{.data.tls\\.crt}" 2>/dev/null)" ] && [ -n "$(kubectl get secret edge-tls -n '"$QUESTION_ID"' -o jsonpath="{.data.tls\\.key}" 2>/dev/null)" ]'

check_criterion "Pod 'edge-proxy' mounts a volume backed by Secret edge-tls" \
  bash -c "kubectl get pod edge-proxy -n '$QUESTION_ID' -o json 2>/dev/null | grep -q '\"edge-tls\"'"

check_criterion "That volume is mounted read-only at /etc/nginx/tls" \
  bash -c "kubectl get pod edge-proxy -n '$QUESTION_ID' -o json 2>/dev/null | grep -A2 '\"mountPath\": \"/etc/nginx/tls\"' | grep -q '\"readOnly\": true'"

check_criterion "Certificate file is present in the container at /etc/nginx/tls/tls.crt" \
  bash -c "kubectl exec -n '$QUESTION_ID' edge-proxy -- test -f /etc/nginx/tls/tls.crt 2>/dev/null"

check_criterion "Key file is present in the container at /etc/nginx/tls/tls.key" \
  bash -c "kubectl exec -n '$QUESTION_ID' edge-proxy -- test -f /etc/nginx/tls/tls.key 2>/dev/null"

print_score
