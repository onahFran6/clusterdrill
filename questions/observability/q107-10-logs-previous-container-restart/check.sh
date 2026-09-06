#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q107-10-logs-previous-container-restart${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

EXPECTED_CODE="$(echo -n "$QUESTION_ID" | sha1sum | cut -c1-10)"

check_criterion "ConfigMap 'recovered-log' exists" \
  resource_exists configmap recovered-log -n "$QUESTION_ID"

check_criterion "ConfigMap 'recovered-log' has the correct code value" \
  [ "$(kget configmap recovered-log '{.data.code}' -n "$QUESTION_ID")" = "$EXPECTED_CODE" ]

print_score
