#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q103-49-combined-fieldselector-setbased-labelselector-delete${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# "stale-1/stale-2 gone" is bundled with "stale-3 and both active pods
# survive" in each criterion - the survivors already exist and are correct
# immediately after setup.sh, before the candidate does anything, so those
# facts alone would trivially pass pre-solve.
check_criterion "'stale-1' was deleted, while 'stale-3', 'active-1', and 'active-2' survive" \
  bash -c '
    NS="'"$QUESTION_ID"'"
    kubectl get pod stale-1 -n "$NS" >/dev/null 2>&1 && exit 1
    kubectl get pod stale-3 -n "$NS" >/dev/null 2>&1 || exit 1
    kubectl get pod active-1 -n "$NS" >/dev/null 2>&1 || exit 1
    kubectl get pod active-2 -n "$NS" >/dev/null 2>&1
  '

check_criterion "'stale-2' was deleted, while 'stale-3', 'active-1', and 'active-2' survive" \
  bash -c '
    NS="'"$QUESTION_ID"'"
    kubectl get pod stale-2 -n "$NS" >/dev/null 2>&1 && exit 1
    kubectl get pod stale-3 -n "$NS" >/dev/null 2>&1 || exit 1
    kubectl get pod active-1 -n "$NS" >/dev/null 2>&1 || exit 1
    kubectl get pod active-2 -n "$NS" >/dev/null 2>&1
  '

print_score
