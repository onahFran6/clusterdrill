#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-10-secret-envfrom-prefix${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'payment-worker' container uses envFrom with secretRef payment-creds" \
  [ "$(kget pod payment-worker '{.spec.containers[0].envFrom[0].secretRef.name}' -n "$QUESTION_ID")" = "payment-creds" ]

check_criterion "envFrom entry uses prefix PAY_" \
  [ "$(kget pod payment-worker '{.spec.containers[0].envFrom[0].prefix}' -n "$QUESTION_ID")" = "PAY_" ]

check_criterion "Container actually sees PAY_API_KEY=pk_test_12345" \
  [ "$(kubectl exec -n "$QUESTION_ID" payment-worker -- sh -c 'echo $PAY_API_KEY' 2>/dev/null)" = "pk_test_12345" ]

check_criterion "Container actually sees PAY_API_SECRET=sk_test_67890" \
  [ "$(kubectl exec -n "$QUESTION_ID" payment-worker -- sh -c 'echo $PAY_API_SECRET' 2>/dev/null)" = "sk_test_67890" ]

print_score
