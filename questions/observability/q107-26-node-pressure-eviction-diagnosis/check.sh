#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q107-26-node-pressure-eviction-diagnosis${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Bundled into one criterion (not "no Evicted remains" / "exists" as
# separate checks) - setup.sh's status-subresource patch to Evicted races
# the kubelet's own status sync for a container that actually exits
# Succeeded, so by the time check.sh runs unsolved, status.reason may no
# longer literally read "Evicted" even though the candidate hasn't touched
# anything yet - that let "no Evicted remains" and "exists" trivially pass
# pre-solve. Gating everything on sizeLimit+Running (the two properties
# that can ONLY be true after the candidate deletes and recreates the pod)
# makes this correctly score 0 pre-solve regardless of that race.
check_criterion "'log-spooler' pod exists, is Running (not stuck Evicted/Failed), and its 'scratch' emptyDir volume has sizeLimit 500Mi" \
  bash -c '
    phase="$(kubectl get pod log-spooler -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
    [ "$phase" = "Running" ] || exit 1
    size_limit="$(kubectl get pod log-spooler -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.volumes[?(@.name==\"scratch\")].emptyDir.sizeLimit}" 2>/dev/null)"
    [ "$size_limit" = "500Mi" ]
  '

print_score
