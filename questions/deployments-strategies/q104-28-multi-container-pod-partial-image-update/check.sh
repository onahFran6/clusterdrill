#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q104-28-multi-container-pod-partial-image-update${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Bundled: setup.sh already leaves proxy on nginx:1.25-alpine and the
# Deployment 2/2 ready, so either alone would trivially pass pre-solve.
# Gating everything on sidecar-agent's image first (the only thing that
# actually changes) makes this correctly score 0 pre-solve.
check_criterion "sidecar-agent is busybox:1.36.1 AND proxy is still nginx:1.25-alpine (untouched) AND 2 ready replicas" \
  bash -c '
    sidecar="$(kubectl get deployment edge-proxy -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[?(@.name==\"sidecar-agent\")].image}" 2>/dev/null)"
    [ "$sidecar" = "busybox:1.36.1" ] || exit 1
    proxy="$(kubectl get deployment edge-proxy -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[?(@.name==\"proxy\")].image}" 2>/dev/null)"
    [ "$proxy" = "nginx:1.25-alpine" ] || exit 1
    kubectl rollout status deployment/edge-proxy -n "'"$QUESTION_ID"'" --timeout=30s >/dev/null 2>&1 || exit 1
    ready="$(kubectl get deployment edge-proxy -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    [ "$ready" = "2" ]
  '

print_score
