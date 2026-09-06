#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q103-15-pod-nodeselector-os-linux${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

pod_running() {
  kubectl wait --for=condition=Ready pod/linux-only -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1
}

check_criterion "Pod 'linux-only' exists in $QUESTION_ID" \
  resource_exists pod linux-only -n "$QUESTION_ID"

check_criterion "Pod 'linux-only' uses image busybox:1.36" \
  [ "$(kget pod linux-only '{.spec.containers[0].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

check_criterion "Pod 'linux-only' declares nodeSelector kubernetes.io/os=linux" \
  [ "$(kget pod linux-only '{.spec.nodeSelector.kubernetes\.io/os}' -n "$QUESTION_ID")" = "linux" ]

check_criterion "Pod 'linux-only' is scheduled and Ready" \
  pod_running

print_score
