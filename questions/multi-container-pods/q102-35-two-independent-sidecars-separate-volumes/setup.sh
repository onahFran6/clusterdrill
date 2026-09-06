#!/usr/bin/env bash
# Idempotent: creates/resets namespace only. The candidate builds the whole
# 3-container Pod from scratch, with two sidecars that each get their OWN
# separate emptyDir (contrast with q102-05's single SHARED emptyDir) -
# testing the understanding that volumes are not shared automatically just
# because two containers are in the same Pod; only containers that mount
# the SAME named volume see the same data.
set -euo pipefail

QUESTION_ID="q102-35-two-independent-sidecars-separate-volumes${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

echo "setup.sh: $QUESTION_ID ready"
