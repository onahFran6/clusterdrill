#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q104-12-canary-shared-selector-split${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'orders-canary' exists with 1 replica on nginx:1.25-alpine" \
  bash -c '
    replicas="$(kubectl get deployment orders-canary -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.replicas}" 2>/dev/null)"
    image="$(kubectl get deployment orders-canary -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    [ "$replicas" = "1" ] && [ "$image" = "nginx:1.25-alpine" ]
  '

check_criterion "Deployment 'orders-canary' pod template carries app=orders, track=canary" \
  bash -c '
    app="$(kubectl get deployment orders-canary -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.metadata.labels.app}" 2>/dev/null)"
    track="$(kubectl get deployment orders-canary -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.metadata.labels.track}" 2>/dev/null)"
    [ "$app" = "orders" ] && [ "$track" = "canary" ]
  '

check_criterion "Deployment 'orders-canary' has 1 ready replica" \
  [ "$(kget deployment orders-canary '{.status.readyReplicas}' -n "$QUESTION_ID")" = "1" ]

check_criterion "Service 'orders-svc' endpoints now include the canary pod (10 total, unchanged selector)" \
  bash -c '
    selector_app="$(kubectl get service orders-svc -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.selector.app}" 2>/dev/null)"
    selector_track="$(kubectl get service orders-svc -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.selector.track}" 2>/dev/null)"
    ep_count="$(kubectl get endpoints orders-svc -n "'"$QUESTION_ID"'" -o jsonpath="{.subsets[*].addresses}" 2>/dev/null | grep -o "\"ip\"" | wc -l | tr -d " ")"
    [ "$selector_app" = "orders" ] && [ -z "$selector_track" ] && [ "$ep_count" = "10" ]
  '

check_criterion "Both Deployments now co-exist as intended (stable untouched, canary added)" \
  bash -c '
    stable_r="$(kubectl get deployment orders-stable -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.replicas}" 2>/dev/null)"
    stable_i="$(kubectl get deployment orders-stable -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    canary_r="$(kubectl get deployment orders-canary -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.replicas}" 2>/dev/null)"
    [ "$stable_r" = "9" ] && [ "$stable_i" = "nginx:1.24-alpine" ] && [ "$canary_r" = "1" ]
  '

print_score
