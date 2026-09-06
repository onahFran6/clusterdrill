#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q101-15-run-pod-env-vars${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'env-demo' exists in $QUESTION_ID" \
  resource_exists pod env-demo -n "$QUESTION_ID"

check_criterion "Pod 'env-demo' runs image 'busybox:1.36'" \
  [ "$(kget pod env-demo '{.spec.containers[0].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

check_criterion "Pod 'env-demo' has env APP_ENV=production" \
  bash -c "kubectl get pod env-demo -n '$QUESTION_ID' -o jsonpath='{.spec.containers[0].env[?(@.name==\"APP_ENV\")].value}' 2>/dev/null | grep -qx production"

check_criterion "Pod 'env-demo' has env RETRY_COUNT=3" \
  bash -c "kubectl get pod env-demo -n '$QUESTION_ID' -o jsonpath='{.spec.containers[0].env[?(@.name==\"RETRY_COUNT\")].value}' 2>/dev/null | grep -qx 3"

print_score
