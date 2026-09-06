#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q107-30-log-rotation-container-restart-history${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

WORK_DIR="$(question_workdir "$QUESTION_ID")"
DIAG_FILE="$WORK_DIR/migrator-diagnosis.txt"

check_criterion "migrator-diagnosis.txt exists with exactly 2 lines, and pod flaky-migrator was left undisturbed (Running/Ready, restartCount >= 2)" \
  bash -c '
    [ -f "$1" ] || exit 1
    [ "$(wc -l < "$1" | tr -d " ")" = "2" ] || exit 1
    phase=$(kubectl get pod flaky-migrator -n "$2" -o jsonpath="{.status.phase}" 2>/dev/null)
    ready=$(kubectl get pod flaky-migrator -n "$2" -o jsonpath="{.status.containerStatuses[0].ready}" 2>/dev/null)
    restarts=$(kubectl get pod flaky-migrator -n "$2" -o jsonpath="{.status.containerStatuses[0].restartCount}" 2>/dev/null || echo 0)
    [ "$phase" = "Running" ] && [ "$ready" = "true" ] && [ "${restarts:-0}" -ge 2 ]
  ' _ "$DIAG_FILE" "$QUESTION_ID"

line1=""
line2=""
if [[ -f "$DIAG_FILE" ]]; then
  line1="$(sed -n '1p' "$DIAG_FILE")"
  line2="$(sed -n '2p' "$DIAG_FILE")"
fi

check_criterion "line 1 is 'exit_code=1'" \
  [ "$line1" = "exit_code=1" ]

check_criterion "line 2 is 'last_log=fatal: dependency unavailable'" \
  [ "$line2" = "last_log=fatal: dependency unavailable" ]

print_score
