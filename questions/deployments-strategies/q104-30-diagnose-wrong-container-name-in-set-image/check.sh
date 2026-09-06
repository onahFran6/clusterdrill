#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q104-30-diagnose-wrong-container-name-in-set-image${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Bundled: setup.sh already leaves search-api at 2/2 ready, so "ready==2"
# alone would trivially pass pre-solve. Gating it on the image actually
# being updated first makes this correctly score 0 pre-solve.
check_criterion "Container 'search-api' image is nginx:1.26-alpine and Deployment has 2 ready replicas" \
  bash -c '
    image="$(kubectl get deployment search-api -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.template.spec.containers[?(@.name==\"search-api\")].image}" 2>/dev/null)"
    [ "$image" = "nginx:1.26-alpine" ] || exit 1
    kubectl rollout status deployment/search-api -n "'"$QUESTION_ID"'" --timeout=30s >/dev/null 2>&1 || exit 1
    ready="$(kubectl get deployment search-api -n "'"$QUESTION_ID"'" -o jsonpath="{.status.readyReplicas}" 2>/dev/null)"
    [ "$ready" = "2" ]
  '

print_score
