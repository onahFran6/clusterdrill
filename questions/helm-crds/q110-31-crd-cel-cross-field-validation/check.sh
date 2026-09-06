#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q110-31-crd-cel-cross-field-validation${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Budget 'q4-cap' exists in $QUESTION_ID" \
  resource_exists budget q4-cap -n "$QUESTION_ID"

check_criterion "Budget 'q4-cap' spec.limit equals 500" \
  [ "$(kget budget q4-cap '{.spec.limit}' -n "$QUESTION_ID")" = "500" ]

check_criterion "Budget 'q4-cap' spec.reserved equals 500 (the largest value satisfying reserved <= limit)" \
  [ "$(kget budget q4-cap '{.spec.reserved}' -n "$QUESTION_ID")" = "500" ]

# Confirm the CEL rule itself was NOT weakened or removed: a throwaway
# server-side dry-run with reserved > limit must still be rejected. Gated
# on q4-cap actually existing first, so this criterion doesn't award a
# free pass in the unsolved state (the CRD itself is never touched by the
# candidate's fix, so in isolation this check is always true).
rule_still_enforced() {
  resource_exists budget q4-cap -n "$QUESTION_ID" || return 1
  kubectl apply --dry-run=server --validate=true -f - >/dev/null 2>&1 <<EOF
apiVersion: finance.clusterdrill.io/v1
kind: Budget
metadata:
  name: q4-cap-dryrun-check
  namespace: $QUESTION_ID
spec:
  limit: 500
  reserved: 501
EOF
  [ "$?" -ne 0 ]
}

check_criterion "CRD rule still rejects reserved > limit after the fix (rule not weakened)" \
  rule_still_enforced

print_score
