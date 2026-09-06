#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q104-31-fix-canary-selector-leak-wrong-traffic-split${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Bundled into one criterion - checking "stable=3, canary=1" alone would
# trivially pass pre-solve (setup.sh already creates them that way and the
# candidate never touches them), and checking "4 running app=recs pods"
# alone could coincidentally pass via the WRONG fix (e.g. deleting 2
# stable pods instead of the leftover Deployment). Requiring the leftover
# Deployment to be gone AND stable/canary intact AND the count to be 4,
# all together, rules out both false-positive paths.
check_criterion "recs-debug-leftover is gone, recs-stable=3/recs-canary=1 are untouched, and exactly 4 Running pods match app=recs" \
  bash -c '
    ! kubectl get deployment recs-debug-leftover -n "'"$QUESTION_ID"'" >/dev/null 2>&1 || exit 1
    stable="$(kubectl get deployment recs-stable -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.replicas}" 2>/dev/null)"
    [ "$stable" = "3" ] || exit 1
    canary="$(kubectl get deployment recs-canary -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.replicas}" 2>/dev/null)"
    [ "$canary" = "1" ] || exit 1
    # A deleted Deployments pods can sit Terminating for a few seconds
    # with .status.phase still reporting "Running" (phase has no distinct
    # Terminating value - only metadata.deletionTimestamp changes), so
    # poll briefly instead of judging on a single snapshot.
    for _ in $(seq 1 15); do
      count="$(kubectl get pods -n "'"$QUESTION_ID"'" -l app=recs --field-selector=status.phase=Running -o name 2>/dev/null | wc -l | tr -d " ")"
      [ "$count" = "4" ] && break
      sleep 1
    done
    [ "$count" = "4" ]
  '

print_score
