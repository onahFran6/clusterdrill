#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q104-38-tune-maxunavailable-percent-maxsurge-fixed${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'catalog-api' uses RollingUpdate with maxUnavailable=\"20%\" and maxSurge=3" \
  bash -c '
    type="$(kubectl get deployment catalog-api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.strategy.type}" 2>/dev/null)"
    [ "$type" = "RollingUpdate" ] || exit 1
    unavail="$(kubectl get deployment catalog-api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.strategy.rollingUpdate.maxUnavailable}" 2>/dev/null)"
    [ "$unavail" = "20%" ] || exit 1
    surge="$(kubectl get deployment catalog-api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.strategy.rollingUpdate.maxSurge}" 2>/dev/null)"
    [ "$surge" = "3" ]
  '

# Gated on the strategy fields too (not just replicas/image) - a default
# Deployment already sits at 5/5 ready with the original image straight out
# of setup.sh, so checking only those would be vacuously true before the
# candidate touches anything (false positive).
check_criterion "Deployment 'catalog-api' still at 5 ready replicas, image unchanged" \
  bash -c '
    unavail="$(kubectl get deployment catalog-api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.strategy.rollingUpdate.maxUnavailable}" 2>/dev/null)"
    surge="$(kubectl get deployment catalog-api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.strategy.rollingUpdate.maxSurge}" 2>/dev/null)"
    replicas="$(kubectl get deployment catalog-api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.replicas}" 2>/dev/null)"
    ready="$(kubectl get deployment catalog-api -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    image="$(kubectl get deployment catalog-api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    [ "$unavail" = "20%" ] && [ "$surge" = "3" ] && [ "$replicas" = "5" ] && [ "$ready" = "5" ] && [ "$image" = "nginx:1.24-alpine" ]
  '

print_score
