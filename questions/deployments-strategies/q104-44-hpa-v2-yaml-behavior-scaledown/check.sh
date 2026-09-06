#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q104-44-hpa-v2-yaml-behavior-scaledown${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "HorizontalPodAutoscaler 'render-farm-hpa' exists (autoscaling/v2) and targets Deployment 'render-farm'" \
  bash -c '
    api_version="$(kubectl get hpa render-farm-hpa -n "'"$QUESTION_ID"'" -o jsonpath="{.apiVersion}" 2>/dev/null)"
    [ "$api_version" = "autoscaling/v2" ] || exit 1
    target="$(kubectl get hpa render-farm-hpa -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.scaleTargetRef.name}" 2>/dev/null)"
    [ "$target" = "render-farm" ]
  '

check_criterion "minReplicas=3, maxReplicas=10, target average CPU utilization is 70%" \
  bash -c '
    min="$(kubectl get hpa render-farm-hpa -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.minReplicas}" 2>/dev/null)"
    max="$(kubectl get hpa render-farm-hpa -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.maxReplicas}" 2>/dev/null)"
    util="$(kubectl get hpa render-farm-hpa -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.metrics[0].resource.target.averageUtilization}" 2>/dev/null)"
    [ "$min" = "3" ] && [ "$max" = "10" ] && [ "$util" = "70" ]
  '

check_criterion "behavior.scaleDown.stabilizationWindowSeconds is 120" \
  [ "$(kget hpa render-farm-hpa '{.spec.behavior.scaleDown.stabilizationWindowSeconds}' -n "$QUESTION_ID")" = "120" ]

print_score
