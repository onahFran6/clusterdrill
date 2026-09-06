#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q107-09-multicontainer-logs-dash-c${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

EXPECTED_TOKEN="$(echo -n "$QUESTION_ID" | md5sum | cut -c1-12)"

check_criterion "ConfigMap 'found-token' exists" \
  resource_exists configmap found-token -n "$QUESTION_ID"

check_criterion "ConfigMap 'found-token' has the correct token value" \
  [ "$(kget configmap found-token '{.data.token}' -n "$QUESTION_ID")" = "$EXPECTED_TOKEN" ]

print_score
