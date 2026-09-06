#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q107-37-custom-columns-extraction${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

WORK_DIR="$(question_workdir "$QUESTION_ID")"
OUT_FILE="$WORK_DIR/fleet-images.txt"

check_criterion "fleet-images.txt exists with exactly 3 lines" \
  bash -c '[ -f "$1" ] && [ "$(wc -l < "$1" | tr -d " ")" = "3" ]' _ "$OUT_FILE"

check_criterion "each line pairs the right pod name with its image (NAME IMAGE, whitespace-separated)" \
  bash -c '
    [ -f "$1" ] || exit 1
    grep -qE "^fleet-alpha[[:space:]]+nginx:1.24-alpine[[:space:]]*$" "$1" || exit 1
    grep -qE "^fleet-beta[[:space:]]+nginx:1.25-alpine[[:space:]]*$" "$1" || exit 1
    grep -qE "^fleet-gamma[[:space:]]+busybox:1.36[[:space:]]*$" "$1"
  ' _ "$OUT_FILE"

print_score
