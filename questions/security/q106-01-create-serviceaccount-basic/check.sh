#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q106-01-create-serviceaccount-basic${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "ServiceAccount 'backup-agent' exists in $QUESTION_ID" \
  resource_exists serviceaccount backup-agent -n "$QUESTION_ID"

print_score
