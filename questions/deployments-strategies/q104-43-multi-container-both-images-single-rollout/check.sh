#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q104-43-multi-container-both-images-single-rollout${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Both containers updated (proxy=nginx:1.25-alpine, sidecar-logger=busybox:1.36) and both replicas ready" \
  bash -c '
    proxy_img="$(kubectl get deployment edge-proxy -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[?(@.name==\"proxy\")].image}" 2>/dev/null)"
    sidecar_img="$(kubectl get deployment edge-proxy -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[?(@.name==\"sidecar-logger\")].image}" 2>/dev/null)"
    [ "$proxy_img" = "nginx:1.25-alpine" ] || exit 1
    [ "$sidecar_img" = "busybox:1.36" ] || exit 1
    ready="$(kubectl get deployment edge-proxy -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    [ "$ready" = "2" ]
  '

check_criterion "Exactly one new revision was created for the combined change (2 revisions total)" \
  bash -c '[ "$(kubectl rollout history deployment/edge-proxy -n "'"$QUESTION_ID"'" 2>/dev/null | grep -cE "^[0-9]+ ")" = "2" ]'

print_score
