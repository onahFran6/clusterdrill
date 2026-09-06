#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q110-22-crd-additional-printer-columns${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

CRD_NAME="invoices.billing.clusterdrill.io"

check_criterion "CRD has an additionalPrinterColumns entry named 'Amount' with jsonPath .spec.amount and type integer" \
  bash -c "kubectl get crd \"$CRD_NAME\" -o json | \
    jq -e '.spec.versions[0].additionalPrinterColumns // [] | any(.name == \"Amount\" and .jsonPath == \".spec.amount\" and .type == \"integer\")' >/dev/null"

check_criterion "CRD has an additionalPrinterColumns entry named 'Status' with jsonPath .spec.status and type string" \
  bash -c "kubectl get crd \"$CRD_NAME\" -o json | \
    jq -e '.spec.versions[0].additionalPrinterColumns // [] | any(.name == \"Status\" and .jsonPath == \".spec.status\" and .type == \"string\")' >/dev/null"

check_criterion "CRD wasn't recreated and Invoice 'inv-1001' still exists unchanged" \
  bash -c "[ \"\$(kubectl get crd '$CRD_NAME' -o name 2>/dev/null)\" = 'customresourcedefinition.apiextensions.k8s.io/$CRD_NAME' ] && \
    [ \"\$(kubectl get invoice inv-1001 -n '$QUESTION_ID' -o jsonpath='{.spec.amount}' 2>/dev/null)\" = '250' ] && \
    kubectl get crd \"$CRD_NAME\" -o json | jq -e '.spec.versions[0].additionalPrinterColumns // [] | length > 0' >/dev/null"

check_criterion "CRD wasn't recreated and Invoice 'inv-1002' still exists unchanged" \
  bash -c "[ \"\$(kubectl get crd '$CRD_NAME' -o name 2>/dev/null)\" = 'customresourcedefinition.apiextensions.k8s.io/$CRD_NAME' ] && \
    [ \"\$(kubectl get invoice inv-1002 -n '$QUESTION_ID' -o jsonpath='{.spec.status}' 2>/dev/null)\" = 'pending' ] && \
    kubectl get crd \"$CRD_NAME\" -o json | jq -e '.spec.versions[0].additionalPrinterColumns // [] | length > 0' >/dev/null"

GET_OUTPUT="$(kubectl get invoices -n "$QUESTION_ID" 2>/dev/null)"

check_criterion "'kubectl get invoices' shows AMOUNT and STATUS column headers" \
  bash -c "echo \"\$0\" | grep -q 'AMOUNT' && echo \"\$0\" | grep -q 'STATUS'" "$GET_OUTPUT"

check_criterion "'kubectl get invoices' shows inv-1001 row with 250 and paid" \
  bash -c "echo \"\$0\" | grep 'inv-1001' | grep -q '250' && echo \"\$0\" | grep 'inv-1001' | grep -q 'paid'" "$GET_OUTPUT"

check_criterion "'kubectl get invoices' shows inv-1002 row with 900 and pending" \
  bash -c "echo \"\$0\" | grep 'inv-1002' | grep -q '900' && echo \"\$0\" | grep 'inv-1002' | grep -q 'pending'" "$GET_OUTPUT"

print_score
