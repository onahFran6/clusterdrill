#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q113-02-fixed-nodeport${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Service 'web-np' exists, type NodePort" \
  bash -c "kubectl get service web-np -n '$QUESTION_ID' >/dev/null 2>&1 && \
    [ \"\$(kubectl get service web-np -n '$QUESTION_ID' -o jsonpath='{.spec.type}')\" = 'NodePort' ]"

check_criterion "Service 'web-np' port 80 with nodePort 30090" \
  bash -c "[ \"\$(kubectl get service web-np -n '$QUESTION_ID' -o jsonpath='{.spec.ports[0].port}')\" = '80' ] && \
    [ \"\$(kubectl get service web-np -n '$QUESTION_ID' -o jsonpath='{.spec.ports[0].nodePort}')\" = '30090' ]"

NODE_IP="$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null | awk '{print $1}')"
check_criterion "functional: curling <node-ip>:30090 (resolved dynamically) returns HTTP 200" \
  bash -c "kubectl run tmp-q113-02-fn --rm -i --restart=Never --image=curlimages/curl:8.10.1 -n '$QUESTION_ID' -- \
    sh -c 'i=0; while [ \$i -lt 6 ]; do code=\$(curl -s -o /dev/null -w \"%{http_code}\" http://$NODE_IP:30090 2>/dev/null); \
    if [ \"\$code\" = \"200\" ]; then exit 0; fi; i=\$((i+1)); sleep 2; done; exit 1'"

print_score
