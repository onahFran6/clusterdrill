#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q109-08-dynamic-provisioning-default-sc${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "PVC 'dynamic-claim' exists in $QUESTION_ID" \
  resource_exists pvc dynamic-claim -n "$QUESTION_ID"

default_sc="$(kubectl get storageclass -o jsonpath='{.items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")].metadata.name}' 2>/dev/null)"
pvc_sc="$(kget pvc dynamic-claim '{.spec.storageClassName}' -n "$QUESTION_ID")"

check_criterion "PVC 'dynamic-claim' resolved to the cluster's default StorageClass" \
  bash -c '[ -n "$1" ] && [ "$1" = "$2" ]' _ "$default_sc" "$pvc_sc"

check_criterion "PVC 'dynamic-claim' requests 500Mi" \
  [ "$(kget pvc dynamic-claim '{.spec.resources.requests.storage}' -n "$QUESTION_ID")" = "500Mi" ]

check_criterion "PVC 'dynamic-claim' requests ReadWriteOnce" \
  [ "$(kget pvc dynamic-claim '{.spec.accessModes[0]}' -n "$QUESTION_ID")" = "ReadWriteOnce" ]

check_criterion "PVC 'dynamic-claim' is Bound (a PV was dynamically provisioned)" \
  [ "$(kget pvc dynamic-claim '{.status.phase}' -n "$QUESTION_ID")" = "Bound" ]

print_score
