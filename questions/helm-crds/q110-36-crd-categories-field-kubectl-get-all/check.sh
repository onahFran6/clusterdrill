#!/usr/bin/env bash
# 'kubectl get all' relies on the client's local discovery cache picking up
# the CRD's new categories, which can lag well past this check's window (a
# default ~10-minute TTL) - not reliable to assert on here, so this checks
# the CRD's spec directly instead, the same source `kubectl get all`
# itself would eventually read from.
set -uo pipefail

QUESTION_ID="q110-36-crd-categories-field-kubectl-get-all${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

CRD_NAME="widgets.catalog.clusterdrill.io"

CATEGORIES="$(kget crd "$CRD_NAME" '{.spec.names.categories}')"
if echo "$CATEGORIES" | grep -q "all"; then
  FIXED=0
else
  FIXED=1
fi

check_criterion "CRD 'widgets.catalog.clusterdrill.io' names.categories includes 'all'" \
  [ "$FIXED" = "0" ]

check_criterion "Fix applied AND instance 'gadget-1' left untouched (sku still GADGET-001)" \
  bash -c "[ '$FIXED' = '0' ] && [ \"\$(kubectl get widget gadget-1 -n '$QUESTION_ID' -o jsonpath='{.spec.sku}')\" = 'GADGET-001' ]"

print_score
