#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q106-04-disable-automount-sa-level${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "ServiceAccount 'metrics-reader' has automountServiceAccountToken=false" \
  [ "$(kget serviceaccount metrics-reader '{.automountServiceAccountToken}' -n "$QUESTION_ID")" = "false" ]

print_score
