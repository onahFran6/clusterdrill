#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q106-40-serviceaccount-automount-pod-override-true${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Gated on the Pod actually existing too - the ServiceAccount's own
# automount=false is already true straight out of setup.sh regardless of
# what the candidate does, so checking it alone would be vacuously true
# before the candidate does anything (false positive).
check_criterion "ServiceAccount 'token-needer' still has automountServiceAccountToken=false (untouched) AND Pod 'token-client' exists" \
  bash -c '
    kubectl get pod token-client -n "'"$QUESTION_ID"'" >/dev/null 2>&1 || exit 1
    [ "$(kubectl get serviceaccount token-needer -n "'"$QUESTION_ID"'" -o jsonpath="{.automountServiceAccountToken}" 2>/dev/null)" = "false" ]
  '

check_criterion "Pod 'token-client' exists, is Running, uses ServiceAccount 'token-needer', and sets automountServiceAccountToken=true at the Pod level" \
  bash -c '
    kubectl get pod token-client -n "'"$QUESTION_ID"'" >/dev/null 2>&1 || exit 1
    [ "$(kubectl get pod token-client -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.serviceAccountName}")" = "token-needer" ] || exit 1
    [ "$(kubectl get pod token-client -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.automountServiceAccountToken}")" = "true" ] || exit 1
    [ "$(kubectl get pod token-client -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}")" = "Running" ]
  '

check_criterion "The projected token volume is actually mounted into the container (Pod-level override wins)" \
  bash -c '
    kubectl exec token-client -n "'"$QUESTION_ID"'" -- test -f /var/run/secrets/kubernetes.io/serviceaccount/token 2>/dev/null
  '

print_score
