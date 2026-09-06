#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q107-17-logs-since-time-window${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

WORK_DIR="$(question_workdir "$QUESTION_ID")"
TAIL_FILE="$WORK_DIR/ticker-tail.txt"

check_criterion "ticker-tail.txt exists" \
  [ -f "$TAIL_FILE" ]

check_criterion "ticker-tail.txt has exactly 5 lines" \
  bash -c '[ -f "$1" ] && [ "$(wc -l < "$1" | tr -d " ")" = "5" ]' _ "$TAIL_FILE"

check_criterion "every line matches 'tick <N>'" \
  bash -c '[ -f "$1" ] && [ "$(grep -cE "^tick [0-9]+\$" "$1" 2>/dev/null)" = "5" ]' _ "$TAIL_FILE"

first_num=""
last_num=""
if [[ -f "$TAIL_FILE" ]]; then
  first_num="$(sed -n '1p' "$TAIL_FILE" | grep -oE '[0-9]+')"
  last_num="$(sed -n '5p' "$TAIL_FILE" | grep -oE '[0-9]+')"
fi

check_criterion "last line's tick number is greater than the first line's (this is the tail, not the head)" \
  bash -c '[ -n "$1" ] && [ -n "$2" ] && [ "$2" -gt "$1" ]' _ "$first_num" "$last_num"

print_score
