#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q107-36-kubectl-top-nodes-basic${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

WORK_DIR="$(question_workdir "$QUESTION_ID")"
OUT_FILE="$WORK_DIR/node-usage.txt"

check_criterion "node-usage.txt exists and is non-empty" \
  bash -c '[ -s "$1" ]' _ "$OUT_FILE"

# Exact CPU/memory values are cluster-load-dependent (this is a shared
# cluster running many questions concurrently) - format is what's testable:
# a NAME column followed by CPU(cores)/CPU(%)/MEMORY(bytes)/MEMORY(%).
check_criterion "node-usage.txt contains at least one node's usage line (name, cpu millicores, cpu percent, memory bytes, memory percent)" \
  bash -c '
    [ -s "$1" ] || exit 1
    grep -qE "^[a-zA-Z0-9.-]+[[:space:]]+[0-9]+m[[:space:]]+[0-9]+%[[:space:]]+[0-9]+Mi[[:space:]]+[0-9]+%" "$1"
  ' _ "$OUT_FILE"

print_score
