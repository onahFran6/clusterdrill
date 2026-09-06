#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q110-47-crd-switch-storage-version${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

CRD_NAME="snapshots.storagepolicy.clusterdrill.io"

V1_STORAGE="$(kget crd "$CRD_NAME" '{.spec.versions[1].storage}')"
V1BETA1_STORAGE="$(kget crd "$CRD_NAME" '{.spec.versions[0].storage}')"
V1_SERVED="$(kget crd "$CRD_NAME" '{.spec.versions[1].served}')"
V1BETA1_SERVED="$(kget crd "$CRD_NAME" '{.spec.versions[0].served}')"

if [ "$V1_STORAGE" = "true" ] && [ "$V1BETA1_STORAGE" = "false" ] && \
   [ "$V1_SERVED" = "true" ] && [ "$V1BETA1_SERVED" = "true" ]; then
  FIXED=0
else
  FIXED=1
fi

check_criterion "CRD storage version flipped to v1 (v1beta1: storage=false, both still served=true)" \
  [ "$FIXED" = "0" ]

check_criterion "Fix applied AND 'archive-q3' still readable via v1beta1 with label unchanged" \
  bash -c "[ '$FIXED' = '0' ] && [ \"\$(kubectl get snapshots.v1beta1.storagepolicy.clusterdrill.io archive-q3 -n '$QUESTION_ID' -o jsonpath='{.spec.label}')\" = 'Archive Q3' ]"

check_criterion "Fix applied AND 'archive-q3' also readable via v1 with the same label" \
  bash -c "[ '$FIXED' = '0' ] && [ \"\$(kubectl get snapshots.v1.storagepolicy.clusterdrill.io archive-q3 -n '$QUESTION_ID' -o jsonpath='{.spec.label}')\" = 'Archive Q3' ]"

print_score
