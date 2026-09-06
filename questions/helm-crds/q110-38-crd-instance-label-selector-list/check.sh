#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q110-38-crd-instance-label-selector-list${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

WORK_DIR="$(question_workdir "$QUESTION_ID")"
OUT_FILE="$WORK_DIR/edge-nodes.txt"

check_criterion "edge-nodes.txt exists at $OUT_FILE" \
  [ -f "$OUT_FILE" ]

check_criterion "edge-nodes.txt lists exactly node-a and node-c, sorted, one per line" \
  bash -c '[ -f "$1" ] && [ "$(sort "$1" | sed "/^\$/d")" = "$(printf "node-a\nnode-c")" ]' _ "$OUT_FILE"

print_score
