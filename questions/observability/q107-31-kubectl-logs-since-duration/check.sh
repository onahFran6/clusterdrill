#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q107-31-kubectl-logs-since-duration${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

WORK_DIR="$(question_workdir "$QUESTION_ID")"
OUT_FILE="$WORK_DIR/heartbeat-recent.txt"

check_criterion "heartbeat-recent.txt exists and is non-empty" \
  bash -c '[ -s "$1" ]' _ "$OUT_FILE"

check_criterion "every line matches 'recent-heartbeat' (old-line-before-cutoff was correctly excluded by --since)" \
  bash -c '
    [ -s "$1" ] || exit 1
    total="$(wc -l < "$1" | tr -d " ")"
    matching="$(grep -cx "recent-heartbeat" "$1" 2>/dev/null)"
    [ "$total" = "$matching" ]
  ' _ "$OUT_FILE"

print_score
