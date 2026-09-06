#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q103-14-delete-pods-by-selector${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

no_scratch_pods_remain() {
  local count
  count="$(kubectl get pods -n "$QUESTION_ID" -l lifecycle=scratch --no-headers 2>/dev/null | wc -l | tr -d ' ')"
  [ "$count" = "0" ]
}

# Exactly two pods remain total, and both are keep-1/keep-2 - this fails if
# the candidate over-deleted (e.g. deleted everything) as well as if they
# under-deleted (scratch pods still present), without relying on a
# trivially-true "keep pod exists" check that would also pass unsolved.
exactly_the_keep_pods_remain() {
  local names
  names="$(kubectl get pods -n "$QUESTION_ID" --no-headers 2>/dev/null | awk '{print $1}' | sort | tr '\n' ',')"
  [ "$names" = "keep-1,keep-2," ]
}

check_criterion "All lifecycle=scratch pods are deleted" \
  no_scratch_pods_remain

check_criterion "Exactly keep-1 and keep-2 remain (nothing else deleted or left over)" \
  exactly_the_keep_pods_remain

print_score
