#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q106-13-readonly-root-filesystem${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'immutable-app' exists in $QUESTION_ID" \
  resource_exists pod immutable-app -n "$QUESTION_ID"

check_criterion "Container 'immutable-app' has readOnlyRootFilesystem=true" \
  [ "$(kget pod immutable-app '{.spec.containers[0].securityContext.readOnlyRootFilesystem}' -n "$QUESTION_ID")" = "true" ]

check_criterion "Container 'immutable-app' mounts a volume at /scratch" \
  bash -c "kubectl get pod immutable-app -n '$QUESTION_ID' \
    -o jsonpath='{.spec.containers[0].volumeMounts[*].mountPath}' | grep -qw /scratch"

kubectl wait --for=condition=Ready pod/immutable-app -n "$QUESTION_ID" --timeout=30s >/dev/null 2>&1

check_criterion "Pod 'immutable-app' reached Running phase" \
  [ "$(kget pod immutable-app '{.status.phase}' -n "$QUESTION_ID")" = "Running" ]

print_score
