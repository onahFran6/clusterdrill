#!/usr/bin/env bash
# Grades ONLY live cluster state - never a client-supplied "done" flag,
# never whether Hint/Solution was opened.
#
# No `set -e` here on purpose: check_criterion returns non-zero on a FAIL,
# which is a normal, expected result per criterion, not a script error. A
# `set -e` would abort the script on the first failed criterion and never
# reach print_score - exactly the false-0 bug verify-question.sh exists to
# catch, so don't reintroduce it here.
set -uo pipefail

QUESTION_ID="q103-20-bulk-label-pods-by-selector${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# All three tier=backend pods picked up rollout=canary. False right after
# setup.sh (none of them have rollout=canary yet), so this alone already
# gates the unsolved-state score to 0 for this criterion.
all_backend_pods_labeled() {
  local count
  count="$(kubectl get pods -n "$QUESTION_ID" -l 'tier=backend,rollout=canary' --no-headers 2>/dev/null | wc -l | tr -d ' ')"
  [ "$count" = "3" ]
}

# Exactly api-1/api-2/api-3 carry rollout=canary anywhere in the namespace -
# fails if web-1, web-2, or sidecar-1 also picked up the label (over-match)
# just as much as if a backend pod was missed (under-match). Also false
# right after setup.sh, since nothing has rollout=canary yet.
exactly_backend_pods_have_new_label() {
  local names
  names="$(kubectl get pods -n "$QUESTION_ID" -l rollout=canary --no-headers 2>/dev/null | awk '{print $1}' | sort | tr '\n' ',')"
  [ "$names" = "api-1,api-2,api-3," ]
}

# Original tier labels must survive untouched - paired with the two checks
# above (both already false pre-fix) so this doesn't introduce a
# trivially-true criterion on its own; it only ever contributes once the
# other two are already earning points.
backend_tier_labels_unchanged() {
  [ "$(kget pod api-1 '{.metadata.labels.tier}' -n "$QUESTION_ID")" = "backend" ] &&
  [ "$(kget pod api-2 '{.metadata.labels.tier}' -n "$QUESTION_ID")" = "backend" ] &&
  [ "$(kget pod api-3 '{.metadata.labels.tier}' -n "$QUESTION_ID")" = "backend" ] &&
  all_backend_pods_labeled
}

check_criterion "All tier=backend pods (api-1, api-2, api-3) are labeled rollout=canary" \
  all_backend_pods_labeled

check_criterion "Exactly api-1, api-2, api-3 are labeled rollout=canary (web-1, web-2, sidecar-1 untouched)" \
  exactly_backend_pods_have_new_label

check_criterion "Existing tier=backend labels are unchanged after the bulk label" \
  backend_tier_labels_unchanged

print_score
