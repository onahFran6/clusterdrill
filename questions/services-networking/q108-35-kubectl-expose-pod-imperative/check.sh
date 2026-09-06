#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q108-35-kubectl-expose-pod-imperative${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Service 'cache-proxy-svc' exists in $QUESTION_ID" \
  resource_exists service cache-proxy-svc -n "$QUESTION_ID"

check_criterion "Service 'cache-proxy-svc' is type ClusterIP" \
  [ "$(kget service cache-proxy-svc '{.spec.type}' -n "$QUESTION_ID")" = "ClusterIP" ]

check_criterion "Service 'cache-proxy-svc' selects app=cache-proxy" \
  [ "$(kget service cache-proxy-svc '{.spec.selector.app}' -n "$QUESTION_ID")" = "cache-proxy" ]

check_criterion "Service 'cache-proxy-svc' listens on port 6379 forwarding to 6379" \
  bash -c "[ \"\$(kubectl get service cache-proxy-svc -n '$QUESTION_ID' -o jsonpath='{.spec.ports[0].port}')\" = '6379' ] && \
    [ \"\$(kubectl get service cache-proxy-svc -n '$QUESTION_ID' -o jsonpath='{.spec.ports[0].targetPort}')\" = '6379' ]"

check_criterion "Service 'cache-proxy-svc' has one ready endpoint matching the Pod's own IP" \
  bash -c '
    pod_ip="$(kubectl get pod cache-proxy -n "'"$QUESTION_ID"'" -o jsonpath="{.status.podIP}" 2>/dev/null)"
    [ -n "$pod_ip" ] || exit 1
    for _ in $(seq 1 15); do
      ep_ip="$(kubectl get endpoints cache-proxy-svc -n "'"$QUESTION_ID"'" -o jsonpath="{.subsets[*].addresses[*].ip}" 2>/dev/null)"
      [ "$ep_ip" = "$pod_ip" ] && exit 0
      sleep 2
    done
    exit 1
  '

print_score
