#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q114-08-can-this-claim-grow${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "StorageClass q114-08-expandable: same provisioner as default class, expandable, labeled" \
  bash -c '
    default_sc="$(kubectl get sc -o jsonpath="{range .items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class==\"true\")]}{.metadata.name}{end}")"
    [ -n "$default_sc" ] || exit 1
    default_prov="$(kubectl get sc "$default_sc" -o jsonpath="{.provisioner}" 2>/dev/null)"
    prov="$(kubectl get sc q114-08-expandable -o jsonpath="{.provisioner}" 2>/dev/null)"
    expand="$(kubectl get sc q114-08-expandable -o jsonpath="{.allowVolumeExpansion}" 2>/dev/null)"
    label="$(kubectl get sc q114-08-expandable -o jsonpath="{.metadata.labels.clusterdrill-question}" 2>/dev/null)"
    [ "$prov" = "$default_prov" ] && [ "$expand" = "true" ] && [ "$label" = "'"$QUESTION_ID"'" ]
  '

check_criterion "PVC q114-08-new-data uses class q114-08-expandable" \
  bash -c '[ "$(kubectl get pvc q114-08-new-data -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.storageClassName}" 2>/dev/null)" = "q114-08-expandable" ]'

check_criterion "PVC q114-08-new-data's requested storage is 500Mi (request, not status.capacity)" \
  bash -c '[ "$(kubectl get pvc q114-08-new-data -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.resources.requests.storage}" 2>/dev/null)" = "500Mi" ]'

print_score
