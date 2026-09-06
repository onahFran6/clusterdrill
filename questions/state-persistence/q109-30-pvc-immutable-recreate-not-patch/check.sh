#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q109-30-pvc-immutable-recreate-not-patch${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "PVC 'resize-test' requests 250Mi of storage" \
  [ "$(kget pvc resize-test '{.spec.resources.requests.storage}' -n "$QUESTION_ID")" = "250Mi" ]

print_score
