#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q111-20-expose-by-named-port${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Container declares port 80 named 'http'" \
  bash -c '
    name="$(kubectl get deployment beam -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].ports[0].name}" 2>/dev/null)"
    port="$(kubectl get deployment beam -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[0].ports[0].containerPort}" 2>/dev/null)"
    [ "$name" = "http" ] && [ "$port" = "80" ]
  '

check_criterion "Service 'beam' is ClusterIP on port 8080 targeting by name 'http'" \
  bash -c '
    type="$(kubectl get service beam -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.type}" 2>/dev/null)"
    port="$(kubectl get service beam -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.ports[0].port}" 2>/dev/null)"
    target="$(kubectl get service beam -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.ports[0].targetPort}" 2>/dev/null)"
    [ "$type" = "ClusterIP" ] && [ "$port" = "8080" ] && [ "$target" = "http" ]
  '

check_criterion "Service 'beam' has 3 endpoints" \
  bash -c '
    for _ in 1 2 3 4 5 6; do
      count="$(kubectl get endpointslices -l kubernetes.io/service-name=beam -n "'"$QUESTION_ID"'" \
        -o jsonpath="{range .items[*].endpoints[*]}{.addresses[0]}{\"\n\"}{end}" 2>/dev/null | grep -c .)"
      [ "$count" = "3" ] && exit 0
      sleep 1
    done
    exit 1
  '

check_criterion "beam:8080 actually answers over the named target port" \
  bash -c '
    pod="$(newest_pod_name "'"$QUESTION_ID"'" app=beam)"
    [ -n "$pod" ] || exit 1
    for _ in 1 2 3 4 5 6; do
      code="$(kubectl exec "$pod" -n "'"$QUESTION_ID"'" -- curl -s -o /dev/null -w "%{http_code}" --max-time 3 beam:8080 2>/dev/null)"
      [ "$code" = "200" ] && exit 0
      sleep 1
    done
    exit 1
  '

print_score
