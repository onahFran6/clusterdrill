#!/usr/bin/env bash
# No "set -e" — a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q104-22-set-progress-deadline${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "progressDeadlineSeconds is 120" \
  [ "$(kget deployment image-resizer '{.spec.progressDeadlineSeconds}' -n "$QUESTION_ID")" = "120" ]

print_score
