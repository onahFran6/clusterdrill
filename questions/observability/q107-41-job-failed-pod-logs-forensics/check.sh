#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q107-41-job-failed-pod-logs-forensics${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

WORK_DIR="$(question_workdir "$QUESTION_ID")"
OUT_FILE="$WORK_DIR/failure-reason.txt"

# Line count isn't fixed at 1: with backoffLimit=1 the Job makes 2 attempts,
# and a selector-based `kubectl logs -l ...` naturally concatenates every
# matching pod's output (each one printing the same message) rather than
# just one - the actual number of failed attempts isn't part of the task.
check_criterion "failure-reason.txt exists, is non-empty, and every line is exactly the error line from the failed Job pod's logs" \
  bash -c '
    [ -s "$1" ] || exit 1
    total="$(wc -l < "$1" | tr -d " ")"
    matching="$(grep -cxF "FATAL: missing required env var DB_HOST" "$1")"
    [ "$total" = "$matching" ]
  ' _ "$OUT_FILE"

print_score
