#!/usr/bin/env bash
# Grades ONLY live cluster state.
# No `set -e` on purpose - see lib/grading.sh header comment.
set -uo pipefail

QUESTION_ID="q104-19-autoscale-deployment-cpu${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

HPA_NAME="$(kubectl get hpa -n "$QUESTION_ID" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)"

check_criterion "A HorizontalPodAutoscaler exists in $QUESTION_ID" \
  [ -n "$HPA_NAME" ]

check_criterion "The HorizontalPodAutoscaler targets Deployment 'checkout-api'" \
  [ "$(kget hpa "$HPA_NAME" '{.spec.scaleTargetRef.name}' -n "$QUESTION_ID")" = "checkout-api" ]

check_criterion "minReplicas is 4" \
  [ "$(kget hpa "$HPA_NAME" '{.spec.minReplicas}' -n "$QUESTION_ID")" = "4" ]

check_criterion "maxReplicas is 12" \
  [ "$(kget hpa "$HPA_NAME" '{.spec.maxReplicas}' -n "$QUESTION_ID")" = "12" ]

check_criterion "Target average CPU utilization is 75%" \
  [ "$(kget hpa "$HPA_NAME" '{.spec.metrics[0].resource.target.averageUtilization}' -n "$QUESTION_ID")" = "75" ]

print_score
