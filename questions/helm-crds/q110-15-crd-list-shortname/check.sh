#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q110-15-crd-list-shortname${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "ConfigMap 'coupon-count' exists in $QUESTION_ID" \
  resource_exists configmap coupon-count -n "$QUESTION_ID"

# Independently count Coupon objects via the full resource name (not the
# short name) so a candidate can't just hardcode "3" without the CRD/instances
# actually existing as described - the ConfigMap's data.total must match the
# real, live count of Coupon custom resources.
coupon_count="$(kubectl get coupons.retail.clusterdrill.io -n "$QUESTION_ID" \
  --no-headers 2>/dev/null | wc -l | tr -d ' ')"
check_criterion "ConfigMap 'coupon-count' has data.total matching the live Coupon count ($coupon_count)" \
  [ "$(kget configmap coupon-count '{.data.total}' -n "$QUESTION_ID")" = "$coupon_count" ]

print_score
