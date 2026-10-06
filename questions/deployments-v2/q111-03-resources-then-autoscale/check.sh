#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q111-03-resources-then-autoscale${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Container requests cpu=200m,memory=128Mi and limits cpu=500m,memory=256Mi" \
  bash -c '
    rcpu="$(kubectl get deployment ingest -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].resources.requests.cpu}" 2>/dev/null)"
    rmem="$(kubectl get deployment ingest -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].resources.requests.memory}" 2>/dev/null)"
    lcpu="$(kubectl get deployment ingest -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].resources.limits.cpu}" 2>/dev/null)"
    lmem="$(kubectl get deployment ingest -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].resources.limits.memory}" 2>/dev/null)"
    [ "$rcpu" = "200m" ] && [ "$rmem" = "128Mi" ] && [ "$lcpu" = "500m" ] && [ "$lmem" = "256Mi" ]
  '

check_criterion "HorizontalPodAutoscaler 'ingest' exists, targeting the Deployment" \
  [ "$(kget hpa ingest '{.spec.scaleTargetRef.name}' -n "$QUESTION_ID")" = "ingest" ]

check_criterion "minReplicas is 2" \
  [ "$(kget hpa ingest '{.spec.minReplicas}' -n "$QUESTION_ID")" = "2" ]

check_criterion "maxReplicas is 6" \
  [ "$(kget hpa ingest '{.spec.maxReplicas}' -n "$QUESTION_ID")" = "6" ]

# kubectl autoscale writes different fields depending on which HPA API
# version the cluster/kubectl negotiate - check autoscaling/v2's
# .spec.metrics[0].resource.target.averageUtilization first, falling back to
# autoscaling/v1's .spec.targetCPUUtilizationPercentage.
check_criterion "Target average CPU utilization is 70%" \
  bash -c '
    v2="$(kubectl get hpa ingest -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.metrics[0].resource.target.averageUtilization}" 2>/dev/null)"
    v1="$(kubectl get hpa ingest -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.targetCPUUtilizationPercentage}" 2>/dev/null)"
    [ "$v2" = "70" ] || [ "$v1" = "70" ]
  '

print_score
