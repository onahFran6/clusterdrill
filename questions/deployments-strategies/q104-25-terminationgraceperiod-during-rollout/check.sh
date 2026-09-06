#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q104-25-terminationgraceperiod-during-rollout${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Single bundled criterion: setup.sh already leaves the Deployment at 3/3
# ready, so "readyReplicas==3" alone would trivially pass pre-solve. Gating
# it on terminationGracePeriodSeconds==5 first (the only thing that
# actually changes) makes this correctly score 0 pre-solve.
check_criterion "Deployment 'worker-queue' has terminationGracePeriodSeconds=5 and 3 ready replicas on that template" \
  bash -c '
    tgps="$(kubectl get deployment worker-queue -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.terminationGracePeriodSeconds}" 2>/dev/null)"
    [ "$tgps" = "5" ] || exit 1
    kubectl rollout status deployment/worker-queue -n "'"$QUESTION_ID"'" --timeout=30s >/dev/null 2>&1 || exit 1
    ready="$(kubectl get deployment worker-queue -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    [ "$ready" = "3" ]
  '

print_score
