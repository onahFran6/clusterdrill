#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q103-37-combined-fieldselector-labelselector-bulk-label${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# "batch-broken and web-1 were NOT labeled" is already true immediately
# after setup.sh, before the candidate does anything - a separate criterion
# for it alone would trivially pass pre-solve. Bundling each Running batch
# pod's positive label together with the two negatives keeps both criteria
# genuinely 0 until the candidate's single combined-selector command
# actually runs.
check_criterion "'batch-ok-1' is labeled synced=true, while 'batch-broken' and 'web-1' are not" \
  bash -c '
    [ "$(kubectl get pod batch-ok-1 -n "'"$QUESTION_ID"'" -o jsonpath="{.metadata.labels.synced}" 2>/dev/null)" = "true" ] || exit 1
    [ "$(kubectl get pod batch-broken -n "'"$QUESTION_ID"'" -o jsonpath="{.metadata.labels.synced}" 2>/dev/null)" != "true" ] || exit 1
    [ "$(kubectl get pod web-1 -n "'"$QUESTION_ID"'" -o jsonpath="{.metadata.labels.synced}" 2>/dev/null)" != "true" ]
  '

check_criterion "'batch-ok-2' is labeled synced=true, while 'batch-broken' and 'web-1' are not" \
  bash -c '
    [ "$(kubectl get pod batch-ok-2 -n "'"$QUESTION_ID"'" -o jsonpath="{.metadata.labels.synced}" 2>/dev/null)" = "true" ] || exit 1
    [ "$(kubectl get pod batch-broken -n "'"$QUESTION_ID"'" -o jsonpath="{.metadata.labels.synced}" 2>/dev/null)" != "true" ] || exit 1
    [ "$(kubectl get pod web-1 -n "'"$QUESTION_ID"'" -o jsonpath="{.metadata.labels.synced}" 2>/dev/null)" != "true" ]
  '

print_score
