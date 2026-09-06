#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q108-49-statefulset-headless-per-pod-stable-dns${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "StatefulSet 'db-cluster' serviceName fixed to 'db-cluster' (the real headless Service)" \
  [ "$(kget statefulset db-cluster '{.spec.serviceName}' -n "$QUESTION_ID")" = "db-cluster" ]

check_criterion "ConfigMap 'dns-check-result' exists with a non-empty 'resolved-ip' key" \
  bash -c "kubectl get configmap dns-check-result -n '$QUESTION_ID' >/dev/null 2>&1 && \
    [ -n \"\$(kubectl get configmap dns-check-result -n '$QUESTION_ID' -o jsonpath='{.data.resolved-ip}')\" ]"

# Re-query both the ConfigMap's recorded value and the pod's live IP inside
# the loop (not just once outside it) - kubelet's DNS registration for a
# freshly-recreated pod can lag briefly, so a stale outside-the-loop
# comparison could never converge.
check_criterion "Recorded resolved-ip matches db-cluster-0's live Pod IP" \
  bash -c '
    for _ in $(seq 1 15); do
      pod_ip="$(kubectl get pod db-cluster-0 -n "'"$QUESTION_ID"'" -o jsonpath="{.status.podIP}" 2>/dev/null)"
      recorded_ip="$(kubectl get configmap dns-check-result -n "'"$QUESTION_ID"'" -o jsonpath="{.data.resolved-ip}" 2>/dev/null)"
      [ -n "$pod_ip" ] && [ "$pod_ip" = "$recorded_ip" ] && exit 0
      sleep 2
    done
    exit 1
  '

print_score
