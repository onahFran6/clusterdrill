#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-23-optional-configmap-key-env${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# Unsolved state: the pod is stuck in CreateContainerConfigError, so this is
# false until the candidate marks FEATURE_Y's configMapKeyRef optional and
# recreates the pod. FEATURE_X's configMapKeyRef is already correct in
# setup.sh and the candidate never needs to touch it, so that check is
# bundled into this same criterion (not split out on its own) - otherwise
# it would already read PASS before the pod is ever fixed.
POD_PHASE="$(kget pod flagreader '{.status.phase}' -n "$QUESTION_ID")"
POD_READY="$(kget pod flagreader '{.status.containerStatuses[0].ready}' -n "$QUESTION_ID")"
FEATURE_X_CM_NAME="$(kget pod flagreader '{.spec.containers[0].env[?(@.name=="FEATURE_X")].valueFrom.configMapKeyRef.name}' -n "$QUESTION_ID")"
FEATURE_X_CM_KEY="$(kget pod flagreader '{.spec.containers[0].env[?(@.name=="FEATURE_X")].valueFrom.configMapKeyRef.key}' -n "$QUESTION_ID")"
check_criterion "Pod 'flagreader' is Running/Ready with FEATURE_X's configMapKeyRef left untouched (app-flags/FEATURE_X)" \
  bash -c "[ '$POD_PHASE' = 'Running' ] && [ '$POD_READY' = 'true' ] && [ '$FEATURE_X_CM_NAME' = 'app-flags' ] && [ '$FEATURE_X_CM_KEY' = 'FEATURE_X' ]"

check_criterion "FEATURE_Y's configMapKeyRef is marked optional: true" \
  [ "$(kget pod flagreader '{.spec.containers[0].env[?(@.name=="FEATURE_Y")].valueFrom.configMapKeyRef.optional}' -n "$QUESTION_ID")" = "true" ]

check_criterion "Container actually sees FEATURE_X=on" \
  [ "$(kubectl exec -n "$QUESTION_ID" flagreader -- sh -c 'echo $FEATURE_X' 2>/dev/null)" = "on" ]

print_score
