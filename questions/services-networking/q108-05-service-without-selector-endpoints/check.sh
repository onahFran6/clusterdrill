#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q108-05-service-without-selector-endpoints${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Service 'legacy-db' exists in $QUESTION_ID" \
  resource_exists service legacy-db -n "$QUESTION_ID"

check_criterion "Service 'legacy-db' has no selector" \
  bash -c "kubectl get service legacy-db -n '$QUESTION_ID' >/dev/null 2>&1 && \
    [ -z \"\$(kubectl get service legacy-db -n '$QUESTION_ID' -o jsonpath='{.spec.selector}')\" ]"

check_criterion "Service 'legacy-db' listens on port 5432" \
  [ "$(kget service legacy-db '{.spec.ports[0].port}' -n "$QUESTION_ID")" = "5432" ]

check_criterion "Endpoints 'legacy-db' exists in $QUESTION_ID" \
  resource_exists endpoints legacy-db -n "$QUESTION_ID"

check_criterion "Endpoints 'legacy-db' targets 10.240.0.55:5432" \
  bash -c "[ \"\$(kubectl get endpoints legacy-db -n '$QUESTION_ID' -o jsonpath='{.subsets[0].addresses[0].ip}')\" = '10.240.0.55' ] && \
    [ \"\$(kubectl get endpoints legacy-db -n '$QUESTION_ID' -o jsonpath='{.subsets[0].ports[0].port}')\" = '5432' ]"

print_score
