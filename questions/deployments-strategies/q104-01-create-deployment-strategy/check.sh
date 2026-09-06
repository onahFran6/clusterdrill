#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q104-01-create-deployment-strategy${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'checkout' exists in $QUESTION_ID" \
  resource_exists deployment checkout -n "$QUESTION_ID"

check_criterion "Deployment 'checkout' has 4 replicas configured" \
  [ "$(kget deployment checkout '{.spec.replicas}' -n "$QUESTION_ID")" = "4" ]

check_criterion "Deployment 'checkout' has 4 ready replicas" \
  [ "$(kget deployment checkout '{.status.readyReplicas}' -n "$QUESTION_ID")" = "4" ]

check_criterion "Deployment 'checkout' uses RollingUpdate strategy" \
  [ "$(kget deployment checkout '{.spec.strategy.type}' -n "$QUESTION_ID")" = "RollingUpdate" ]

check_criterion "Deployment 'checkout' has maxSurge=1" \
  [ "$(kget deployment checkout '{.spec.strategy.rollingUpdate.maxSurge}' -n "$QUESTION_ID")" = "1" ]

check_criterion "Deployment 'checkout' has maxUnavailable=0" \
  [ "$(kget deployment checkout '{.spec.strategy.rollingUpdate.maxUnavailable}' -n "$QUESTION_ID")" = "0" ]

check_criterion "Deployment 'checkout' pods use image nginx:1.25-alpine" \
  [ "$(kget deployment checkout '{.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")" = "nginx:1.25-alpine" ]

check_criterion "Deployment 'checkout' pod template labeled app=checkout" \
  [ "$(kget deployment checkout '{.spec.template.metadata.labels.app}' -n "$QUESTION_ID")" = "checkout" ]

print_score
