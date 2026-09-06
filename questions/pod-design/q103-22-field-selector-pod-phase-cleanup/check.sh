#!/usr/bin/env bash
# Grades ONLY live cluster state - never a client-supplied "done" flag.
# No `set -e`: check_criterion returns non-zero on a FAIL, which is a
# normal per-criterion result, not a script error.
set -uo pipefail

QUESTION_ID="q103-22-field-selector-pod-phase-cleanup${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

no_succeeded_pods_remain() {
  local count
  count="$(kubectl get pods -n "$QUESTION_ID" --field-selector=status.phase=Succeeded --no-headers 2>/dev/null | wc -l | tr -d ' ')"
  [ "$count" = "0" ]
}

# Exactly two pods remain total, and both are worker-1/worker-2 - this
# fails if the candidate over-deleted (e.g. deleted everything) as well as
# if they under-deleted (a debug-* pod still present), without relying on
# a trivially-true "worker pod exists" check that would also pass unsolved.
exactly_the_worker_pods_remain() {
  local names
  names="$(kubectl get pods -n "$QUESTION_ID" --no-headers 2>/dev/null | awk '{print $1}' | sort | tr '\n' ',')"
  [ "$names" = "worker-1,worker-2," ]
}

check_criterion "All Succeeded pods are deleted" \
  no_succeeded_pods_remain

check_criterion "Exactly worker-1 and worker-2 remain (nothing else deleted or left over)" \
  exactly_the_worker_pods_remain

print_score
