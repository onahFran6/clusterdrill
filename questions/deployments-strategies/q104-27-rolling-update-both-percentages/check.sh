#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q104-27-rolling-update-both-percentages${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Bundled: setup.sh already leaves catalog-svc at 4/4 ready, so "ready==4"
# alone would trivially pass pre-solve. Gating it on the explicit
# maxSurge/maxUnavailable percentages first makes this correctly score 0.
check_criterion "Deployment 'catalog-svc' has maxSurge=50% and maxUnavailable=25% (as strings) and 4 ready replicas" \
  bash -c '
    surge="$(kubectl get deployment catalog-svc -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.strategy.rollingUpdate.maxSurge}" 2>/dev/null)"
    [ "$surge" = "50%" ] || exit 1
    unavail="$(kubectl get deployment catalog-svc -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.strategy.rollingUpdate.maxUnavailable}" 2>/dev/null)"
    [ "$unavail" = "25%" ] || exit 1
    kubectl rollout status deployment/catalog-svc -n "'"$QUESTION_ID"'" --timeout=30s >/dev/null 2>&1 || exit 1
    ready="$(kubectl get deployment catalog-svc -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    [ "$ready" = "4" ]
  '

print_score
