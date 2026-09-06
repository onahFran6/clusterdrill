#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q108-21-clusterip-to-nodeport-type-change${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# NOTE: "Service exists" and "endpoints are ready" are both already true right
# after setup.sh (it creates catalog-api-svc as ClusterIP with a matching
# selector). Bundling them with the type/nodePort change that setup.sh does
# NOT make ensures nothing here scores until the candidate actually converts
# the Service to NodePort:30081.
check_criterion "Service 'catalog-api-svc' is type NodePort with nodePort 30081 and ready endpoints matching catalog-api's pods" \
  bash -c "
    [ \"\$(kubectl get service catalog-api-svc -n '$QUESTION_ID' -o jsonpath='{.spec.type}' 2>/dev/null)\" = 'NodePort' ] &&
    [ \"\$(kubectl get service catalog-api-svc -n '$QUESTION_ID' -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)\" = '30081' ] &&
    ep_ips=\$(kubectl get endpoints catalog-api-svc -n '$QUESTION_ID' -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null) &&
    [ -n \"\$ep_ips\" ] &&
    ep_count=\$(echo \"\$ep_ips\" | wc -w | tr -d ' ') &&
    pod_ips=\$(kubectl get pods -n '$QUESTION_ID' -l app=catalog-api -o jsonpath='{.items[*].status.podIP}' 2>/dev/null) &&
    pod_count=\$(echo \"\$pod_ips\" | wc -w | tr -d ' ') &&
    [ \"\$ep_count\" = \"\$pod_count\" ] &&
    [ \"\$ep_count\" -gt 0 ]
  "

print_score
