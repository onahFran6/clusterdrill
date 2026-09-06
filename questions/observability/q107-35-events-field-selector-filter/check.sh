#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q107-35-events-field-selector-filter${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

WORK_DIR="$(question_workdir "$QUESTION_ID")"
OUT_FILE="$WORK_DIR/broken-app-warnings.txt"

check_criterion "broken-app-warnings.txt exists and is non-empty" \
  bash -c '[ -s "$1" ]' _ "$OUT_FILE"

check_criterion "every line names only broken-app (the field-selector correctly excluded healthy-app)" \
  bash -c '
    [ -s "$1" ] || exit 1
    total="$(wc -l < "$1" | tr -d " ")"
    matching="$(grep -cx "broken-app" "$1" 2>/dev/null)"
    [ "$total" = "$matching" ]
  ' _ "$OUT_FILE"

print_score
