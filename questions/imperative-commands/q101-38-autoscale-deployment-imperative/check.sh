#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q101-38-autoscale-deployment-imperative${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "HorizontalPodAutoscaler 'api-server' exists in $QUESTION_ID" \
  resource_exists hpa api-server -n "$QUESTION_ID"

check_criterion "HPA 'api-server' targets Deployment 'api-server'" \
  [ "$(kget hpa api-server '{.spec.scaleTargetRef.name}' -n "$QUESTION_ID")" = "api-server" ]

check_criterion "HPA 'api-server' has minReplicas=2" \
  [ "$(kget hpa api-server '{.spec.minReplicas}' -n "$QUESTION_ID")" = "2" ]

check_criterion "HPA 'api-server' has maxReplicas=5" \
  [ "$(kget hpa api-server '{.spec.maxReplicas}' -n "$QUESTION_ID")" = "5" ]

check_criterion "HPA 'api-server' targets 60% average CPU utilization" \
  bash -c "
    TARGET=\$(kubectl get hpa api-server -n '$QUESTION_ID' -o jsonpath='{.spec.metrics[0].resource.target.averageUtilization}' 2>/dev/null)
    [ \"\$TARGET\" = '60' ]
  "

print_score
