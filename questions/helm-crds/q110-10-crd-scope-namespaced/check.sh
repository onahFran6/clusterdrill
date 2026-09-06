#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q110-10-crd-scope-namespaced${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

CRD_NAME="menuitems.diner.clusterdrill.io"

check_criterion "CRD '$CRD_NAME' exists" \
  resource_exists crd "$CRD_NAME"

check_criterion "CRD carries the clusterdrill-question label" \
  [ "$(kget crd "$CRD_NAME" '{.metadata.labels.clusterdrill-question}')" = "$QUESTION_ID" ]

check_criterion "CRD scope is Namespaced" \
  [ "$(kget crd "$CRD_NAME" '{.spec.scope}')" = "Namespaced" ]

check_criterion "CRD short name 'mi' is registered" \
  bash -c '
    kubectl get crd "$0" -o jsonpath="{.spec.names.shortNames}" 2>/dev/null | grep -q "mi"
  ' "$CRD_NAME"

check_criterion "MenuItem instance is listable via short name 'mi' in $QUESTION_ID" \
  bash -c '
    kubectl get mi -n "$0" --no-headers 2>/dev/null | grep -q "special-1"
  ' "$QUESTION_ID"

check_criterion "MenuItem 'special-1' has spec.dish=ramen" \
  [ "$(kget menuitem special-1 '{.spec.dish}' -n "$QUESTION_ID")" = "ramen" ]

print_score
