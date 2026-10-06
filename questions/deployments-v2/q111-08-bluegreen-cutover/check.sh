#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q111-08-bluegreen-cutover${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'portal-green' runs nginx:1.27, labeled color=green, 3/3 ready" \
  bash -c '
    image="$(kubectl get deployment portal-green -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    color="$(kubectl get deployment portal-green -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.metadata.labels.color}" 2>/dev/null)"
    ready="$(kubectl get deployment portal-green -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    [ "$image" = "nginx:1.27" ] && [ "$color" = "green" ] && [ "$ready" = "3" ]
  '

check_criterion "Service 'portal' selector is app=portal, color=green" \
  bash -c '
    app="$(kubectl get service portal -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.selector.app}" 2>/dev/null)"
    color="$(kubectl get service portal -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.selector.color}" 2>/dev/null)"
    [ "$app" = "portal" ] && [ "$color" = "green" ]
  '

check_criterion "Deployment 'portal-blue' kept at 0 replicas for rollback" \
  [ "$(kget deployment portal-blue '{.spec.replicas}' -n "$QUESTION_ID")" = "0" ]

print_score
