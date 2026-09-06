#!/usr/bin/env bash
# Grades ONLY live cluster state - never a client-supplied "done" flag,
# never whether Hint/Solution was opened.
#
# No `set -e` here on purpose: check_criterion returns non-zero on a FAIL,
# which is a normal, expected result per criterion, not a script error. A
# `set -e` would abort the script on the first failed criterion and never
# reach print_score.
set -uo pipefail

QUESTION_ID="q101-33-hpa-fights-manual-scale${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# hpa_no_longer_forces_three: the real diagnosis step. Right after
# setup.sh, the HPA exists with minReplicas=3, which is exactly what keeps
# forcing a manual `kubectl scale --replicas=1` back up - so this is FALSE
# on the unsolved state. Any imperative technique that removes that floor
# is accepted: lowering minReplicas to 1 (or below), or deleting the HPA
# outright so nothing is left to re-enforce a floor.
hpa_no_longer_forces_three() {
  local min
  if ! resource_exists hpa email-worker -n "$QUESTION_ID"; then
    return 0
  fi
  min="$(kget hpa email-worker '{.spec.minReplicas}' -n "$QUESTION_ID")"
  [[ "$min" =~ ^[0-9]+$ ]] && [ "$min" -le 1 ]
}

check_criterion "HPA 'email-worker' no longer enforces a floor above 1 replica (minReplicas lowered to <=1, or the HPA was removed)" \
  hpa_no_longer_forces_three

# deployment_settles_at_one: bundles "reaches 1" AND "stays at 1" into one
# criterion, since on the unsolved state the Deployment sits at 3 replicas
# forever (the HPA keeps re-enforcing minReplicas=3), so this never
# trivially passes before the candidate acts.
#
# Phase 1 waits (up to 30s) for the Deployment to actually reach 1/1 - a
# just-issued `kubectl scale` needs a moment for old pods to terminate
#.
# Phase 2 then re-polls for 20s to confirm it STAYS at 1/1 - i.e. the HPA
# genuinely stopped fighting the scale-down, not just a lucky snapshot
# mid-reconcile (confirmed empirically in this cluster: with the fix
# applied and behavior.stabilizationWindowSeconds=0, it stays put; without
# the fix, it never even reaches 1/1 in phase 1).
deployment_settles_at_one() {
  local max_wait=30 waited=0 spec ready

  while :; do
    spec="$(kget deployment email-worker '{.spec.replicas}' -n "$QUESTION_ID")"
    ready="$(kget deployment email-worker '{.status.readyReplicas}' -n "$QUESTION_ID")"
    if [ "$spec" = "1" ] && [ "$ready" = "1" ]; then
      break
    fi
    if [ "$waited" -ge "$max_wait" ]; then
      return 1
    fi
    sleep 3
    waited=$((waited + 3))
  done

  local i
  for i in 1 2 3 4; do
    sleep 5
    spec="$(kget deployment email-worker '{.spec.replicas}' -n "$QUESTION_ID")"
    ready="$(kget deployment email-worker '{.status.readyReplicas}' -n "$QUESTION_ID")"
    if [ "$spec" != "1" ] || [ "$ready" != "1" ]; then
      return 1
    fi
  done
  return 0
}

check_criterion "Deployment 'email-worker' reaches exactly 1 replica and stays there (not scaled back up by the HPA)" \
  deployment_settles_at_one

print_score
