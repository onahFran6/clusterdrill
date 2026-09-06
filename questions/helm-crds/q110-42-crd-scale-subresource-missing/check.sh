#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q110-42-crd-scale-subresource-missing${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

CRD_NAME="workerpools.ops.clusterdrill.io"

SPEC_PATH="$(kget crd "$CRD_NAME" '{.spec.versions[0].subresources.scale.specReplicasPath}')"
STATUS_PATH="$(kget crd "$CRD_NAME" '{.spec.versions[0].subresources.scale.statusReplicasPath}')"
SELECTOR_PATH="$(kget crd "$CRD_NAME" '{.spec.versions[0].subresources.scale.labelSelectorPath}')"

if [ "$SPEC_PATH" = ".spec.replicas" ] && [ "$STATUS_PATH" = ".status.replicas" ] && [ "$SELECTOR_PATH" = ".status.selector" ]; then
  FIXED=0
else
  FIXED=1
fi

check_criterion "CRD 'workerpools.ops.clusterdrill.io' v1 has a correctly-configured scale subresource" \
  [ "$FIXED" = "0" ]

# Gated on the scale subresource actually being configured - otherwise a
# direct 'kubectl patch workerpool ... spec.replicas=5' (bypassing
# kubectl scale entirely) would score here without ever fixing the CRD.
check_criterion "Scale subresource works AND WorkerPool 'pool-a' spec.replicas is 5" \
  bash -c "[ '$FIXED' = '0' ] && [ \"\$(kubectl get workerpool pool-a -n '$QUESTION_ID' -o jsonpath='{.spec.replicas}')\" = '5' ]"

print_score
