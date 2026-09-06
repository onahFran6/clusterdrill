#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q104-13-canary-increase-weight${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'payments-canary' scaled to 5 replicas, all ready, image unchanged" \
  bash -c '
    replicas="$(kubectl get deployment payments-canary -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.replicas}" 2>/dev/null)"
    ready="$(kubectl get deployment payments-canary -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    image="$(kubectl get deployment payments-canary -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    [ "$replicas" = "5" ] && [ "$ready" = "5" ] && [ "$image" = "nginx:1.25-alpine" ]
  '

check_criterion "Deployment 'payments-stable' scaled to 5 replicas, all ready, image unchanged" \
  bash -c '
    replicas="$(kubectl get deployment payments-stable -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.replicas}" 2>/dev/null)"
    ready="$(kubectl get deployment payments-stable -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    image="$(kubectl get deployment payments-stable -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    [ "$replicas" = "5" ] && [ "$ready" = "5" ] && [ "$image" = "nginx:1.24-alpine" ]
  '

check_criterion "Service 'payments-svc' still load-balances across exactly 10 endpoints, split 5/5" \
  bash -c '
    ep_count="$(kubectl get endpoints payments-svc -n "'"$QUESTION_ID"'" -o jsonpath="{.subsets[*].addresses}" 2>/dev/null | grep -o "\"ip\"" | wc -l | tr -d " ")"
    stable_r="$(kubectl get deployment payments-stable -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.replicas}" 2>/dev/null)"
    canary_r="$(kubectl get deployment payments-canary -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.replicas}" 2>/dev/null)"
    [ "$ep_count" = "10" ] && [ "$stable_r" = "5" ] && [ "$canary_r" = "5" ]
  '

print_score
