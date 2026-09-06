#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q106-16-fsgroup-shared-volume${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'shared-writer' exists in $QUESTION_ID" \
  resource_exists pod shared-writer -n "$QUESTION_ID"

check_criterion "Pod 'shared-writer' securityContext.fsGroup is 2000" \
  [ "$(kget pod shared-writer '{.spec.securityContext.fsGroup}' -n "$QUESTION_ID")" = "2000" ]

check_criterion "Container 'writer' mounts volume 'data' at /data" \
  bash -c "kubectl get pod shared-writer -n '$QUESTION_ID' \
    -o jsonpath='{.spec.containers[?(@.name==\"writer\")].volumeMounts[*].mountPath}' | grep -qw /data"

check_criterion "Container 'reader' mounts volume 'data' at /data" \
  bash -c "kubectl get pod shared-writer -n '$QUESTION_ID' \
    -o jsonpath='{.spec.containers[?(@.name==\"reader\")].volumeMounts[*].mountPath}' | grep -qw /data"

check_criterion "Volume 'data' is an emptyDir" \
  bash -c "kubectl get pod shared-writer -n '$QUESTION_ID' \
    -o jsonpath='{.spec.volumes[?(@.name==\"data\")].emptyDir}' | grep -q '{}'"

print_score
