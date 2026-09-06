#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q109-02-emptydir-sizelimit-memory${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'cache-pod' exists in $QUESTION_ID" \
  resource_exists pod cache-pod -n "$QUESTION_ID"

check_criterion "Volume 'fast-cache' uses medium Memory" \
  [ "$(kget pod cache-pod '{.spec.volumes[?(@.name=="fast-cache")].emptyDir.medium}' -n "$QUESTION_ID")" = "Memory" ]

check_criterion "Volume 'fast-cache' has sizeLimit 64Mi" \
  [ "$(kget pod cache-pod '{.spec.volumes[?(@.name=="fast-cache")].emptyDir.sizeLimit}' -n "$QUESTION_ID")" = "64Mi" ]

check_criterion "Container 'cache' mounts 'fast-cache' at /cache" \
  [ "$(kget pod cache-pod '{.spec.containers[0].volumeMounts[?(@.name=="fast-cache")].mountPath}' -n "$QUESTION_ID")" = "/cache" ]

print_score
