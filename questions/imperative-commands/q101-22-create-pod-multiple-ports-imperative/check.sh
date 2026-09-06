#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q101-22-create-pod-multiple-ports-imperative${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

pod_ready() {
  kubectl wait --for=condition=Ready pod/multiport-app -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1
}

check_criterion "Pod 'multiport-app' exists in $QUESTION_ID and is Ready" \
  pod_ready

check_criterion "Pod 'multiport-app' runs image 'nginx:1.25-alpine'" \
  [ "$(kget pod multiport-app '{.spec.containers[0].image}' -n "$QUESTION_ID")" = "nginx:1.25-alpine" ]

check_criterion "Pod 'multiport-app' container has exactly 2 ports" \
  [ "$(kget pod multiport-app '{.spec.containers[0].ports[*].containerPort}' -n "$QUESTION_ID" | wc -w | tr -d ' ')" = "2" ]

check_criterion "Pod 'multiport-app' has containerPort=8080 named 'http'" \
  bash -c "kubectl get pod multiport-app -n '$QUESTION_ID' -o jsonpath='{range .spec.containers[0].ports[?(@.containerPort==8080)]}{.name}{end}' 2>/dev/null | grep -qx 'http'"

check_criterion "Pod 'multiport-app' has containerPort=8443 named 'https'" \
  bash -c "kubectl get pod multiport-app -n '$QUESTION_ID' -o jsonpath='{range .spec.containers[0].ports[?(@.containerPort==8443)]}{.name}{end}' 2>/dev/null | grep -qx 'https'"

print_score
