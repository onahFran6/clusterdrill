#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q104-15-fix-stuck-rollout-bad-probe${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'checkout-api' readinessProbe path fixed to / (image still 1.25-alpine)" \
  bash -c '
    path="$(kubectl get deployment checkout-api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].readinessProbe.httpGet.path}" 2>/dev/null)"
    image="$(kubectl get deployment checkout-api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    [ "$path" = "/" ] && [ "$image" = "nginx:1.25-alpine" ]
  '

check_criterion "Deployment 'checkout-api' rollout completed: 3 ready replicas on the new image" \
  bash -c '
    image="$(kubectl get deployment checkout-api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)"
    ready="$(kubectl get deployment checkout-api -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    updated="$(kubectl get deployment checkout-api -n "'"$QUESTION_ID"'" -o jsonpath="{.status.updatedReplicas}" 2>/dev/null)"
    [ "$image" = "nginx:1.25-alpine" ] && [ "$ready" = "3" ] && [ "$updated" = "3" ]
  '

check_criterion "No pod still runs the readiness probe pointed at /does-not-exist" \
  bash -c '
    bad="$(kubectl get pods -n "'"$QUESTION_ID"'" -l app=checkout-api -o jsonpath="{range .items[*]}{.spec.containers[0].readinessProbe.httpGet.path}{\"\n\"}{end}" 2>/dev/null | grep -c "does-not-exist")"
    [ "$bad" = "0" ]
  '

print_score
