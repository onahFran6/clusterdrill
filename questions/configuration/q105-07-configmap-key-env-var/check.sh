#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-07-configmap-key-env-var${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'storefront' has env var CHECKOUT_FLAG sourced from a configMapKeyRef" \
  [ "$(kget pod storefront '{.spec.containers[0].env[?(@.name=="CHECKOUT_FLAG")].valueFrom.configMapKeyRef.name}' -n "$QUESTION_ID")" = "feature-flags" ]

check_criterion "That configMapKeyRef points at key NEW_CHECKOUT" \
  [ "$(kget pod storefront '{.spec.containers[0].env[?(@.name=="CHECKOUT_FLAG")].valueFrom.configMapKeyRef.key}' -n "$QUESTION_ID")" = "NEW_CHECKOUT" ]

check_criterion "Exactly one container env var is defined (DARK_MODE was not also added)" \
  [ "$(kget pod storefront '{range .spec.containers[0].env[*]}x{end}' -n "$QUESTION_ID")" = "x" ]

check_criterion "Container actually sees CHECKOUT_FLAG=enabled" \
  [ "$(kubectl exec -n "$QUESTION_ID" storefront -- sh -c 'echo $CHECKOUT_FLAG' 2>/dev/null)" = "enabled" ]

print_score
