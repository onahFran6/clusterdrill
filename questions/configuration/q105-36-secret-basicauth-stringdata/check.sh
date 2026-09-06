#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-36-secret-basicauth-stringdata${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Secret 'proxy-creds' exists with type kubernetes.io/basic-auth" \
  bash -c '
    [ "$(kubectl get secret proxy-creds -n "'"$QUESTION_ID"'" -o jsonpath="{.type}" 2>/dev/null)" = "kubernetes.io/basic-auth" ]
  '

check_criterion "Secret 'proxy-creds' has username=svc-proxy and password=Tr0ub4dor&3" \
  bash -c '
    u="$(kubectl get secret proxy-creds -n "'"$QUESTION_ID"'" -o jsonpath="{.data.username}" 2>/dev/null | base64 -d 2>/dev/null)"
    [ "$u" = "svc-proxy" ] || exit 1
    p="$(kubectl get secret proxy-creds -n "'"$QUESTION_ID"'" -o jsonpath="{.data.password}" 2>/dev/null | base64 -d 2>/dev/null)"
    [ "$p" = "Tr0ub4dor&3" ]
  '

check_criterion "Pod 'auth-proxy' has AUTH_USER sourced from secretKeyRef proxy-creds/username" \
  bash -c '
    n="$(kubectl get pod auth-proxy -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].env[?(@.name==\"AUTH_USER\")].valueFrom.secretKeyRef.name}" 2>/dev/null)"
    [ "$n" = "proxy-creds" ] || exit 1
    k="$(kubectl get pod auth-proxy -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].env[?(@.name==\"AUTH_USER\")].valueFrom.secretKeyRef.key}" 2>/dev/null)"
    [ "$k" = "username" ]
  '

check_criterion "Pod 'auth-proxy' has AUTH_PASS sourced from secretKeyRef proxy-creds/password" \
  bash -c '
    n="$(kubectl get pod auth-proxy -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].env[?(@.name==\"AUTH_PASS\")].valueFrom.secretKeyRef.name}" 2>/dev/null)"
    [ "$n" = "proxy-creds" ] || exit 1
    k="$(kubectl get pod auth-proxy -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.containers[0].env[?(@.name==\"AUTH_PASS\")].valueFrom.secretKeyRef.key}" 2>/dev/null)"
    [ "$k" = "password" ]
  '

check_criterion "Container actually sees AUTH_USER=svc-proxy and AUTH_PASS=Tr0ub4dor&3" \
  bash -c '
    u="$(kubectl exec -n "'"$QUESTION_ID"'" auth-proxy -- sh -c "echo \$AUTH_USER" 2>/dev/null)"
    [ "$u" = "svc-proxy" ] || exit 1
    p="$(kubectl exec -n "'"$QUESTION_ID"'" auth-proxy -- sh -c "echo \$AUTH_PASS" 2>/dev/null)"
    [ "$p" = "Tr0ub4dor&3" ]
  '

print_score
