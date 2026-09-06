#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q108-04-externalname-service${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Service 'billing-db' exists in $QUESTION_ID" \
  resource_exists service billing-db -n "$QUESTION_ID"

check_criterion "Service 'billing-db' is type ExternalName" \
  [ "$(kget service billing-db '{.spec.type}' -n "$QUESTION_ID")" = "ExternalName" ]

check_criterion "Service 'billing-db' externalName points at db.internal.example.com" \
  [ "$(kget service billing-db '{.spec.externalName}' -n "$QUESTION_ID")" = "db.internal.example.com" ]

check_criterion "Service 'billing-db' has no selector" \
  bash -c "kubectl get service billing-db -n '$QUESTION_ID' >/dev/null 2>&1 && \
    [ -z \"\$(kubectl get service billing-db -n '$QUESTION_ID' -o jsonpath='{.spec.selector}')\" ]"

print_score
