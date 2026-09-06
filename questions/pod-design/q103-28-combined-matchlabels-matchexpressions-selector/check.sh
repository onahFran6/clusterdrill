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

QUESTION_ID="q103-28-combined-matchlabels-matchexpressions-selector${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Single bundled criterion (per the recurring-bug note): right after
# setup.sh no pod carries promote=true yet, so this is naturally 0/1 on the
# unsolved state - no separate "nothing is labeled yet" criterion needed.
# It checks BOTH halves at once: exactly the correct three pods are labeled
# promote=true, AND every pod's original tier/env labels are untouched (so
# a candidate can't pass by e.g. relabeling env instead of using a correct
# selector).
exactly_the_right_pods_are_promoted() {
  local promoted
  promoted="$(kubectl get pods -n "$QUESTION_ID" -l promote=true --no-headers 2>/dev/null \
    | awk '{print $1}' | sort | tr '\n' ',')"
  [ "$promoted" = "worker-prod,worker-prod-2,worker-staging," ] || return 1

  local expected name tier env actual_tier actual_env
  for expected in \
    "worker-staging:worker:staging" \
    "worker-prod:worker:prod" \
    "worker-prod-2:worker:prod" \
    "worker-dev:worker:dev" \
    "worker-test:worker:test" \
    "web-staging:web:staging" \
    "web-prod:web:prod"
  do
    IFS=':' read -r name tier env <<< "$expected"
    actual_tier="$(kget pod "$name" '{.metadata.labels.tier}' -n "$QUESTION_ID")"
    actual_env="$(kget pod "$name" '{.metadata.labels.env}' -n "$QUESTION_ID")"
    [ "$actual_tier" = "$tier" ] || return 1
    [ "$actual_env" = "$env" ] || return 1
  done

  return 0
}

check_criterion "Exactly worker-staging, worker-prod, and worker-prod-2 are labeled promote=true, with every pod's original tier/env labels unchanged" \
  exactly_the_right_pods_are_promoted

print_score
