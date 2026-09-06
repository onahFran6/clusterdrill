#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-39-configmap-patch-merge-preserve-keys${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Bundled into one criterion (rather than three separate always-true-once-
# created ones) so an unsolved ConfigMap - which already has LOG_LEVEL and
# TIMEOUT from setup.sh, just not yet MAX_RETRIES - correctly scores 0 here
# instead of a false-positive partial pass.
check_criterion "MAX_RETRIES=5 was added AND LOG_LEVEL=info/TIMEOUT=30 remain unchanged" \
  bash -c '
    lvl="$(kubectl get configmap app-settings -n "'"$QUESTION_ID"'" -o jsonpath="{.data.LOG_LEVEL}" 2>/dev/null)"
    [ "$lvl" = "info" ] || exit 1
    to="$(kubectl get configmap app-settings -n "'"$QUESTION_ID"'" -o jsonpath="{.data.TIMEOUT}" 2>/dev/null)"
    [ "$to" = "30" ] || exit 1
    mr="$(kubectl get configmap app-settings -n "'"$QUESTION_ID"'" -o jsonpath="{.data.MAX_RETRIES}" 2>/dev/null)"
    [ "$mr" = "5" ]
  '

print_score
