#!/usr/bin/env bash
# Idempotent: creates/resets namespace q102-14-sidecar-distinct-resources.
# No pod is seeded - the candidate creates the whole Pod from scratch.
set -euo pipefail

QUESTION_ID="q102-14-sidecar-distinct-resources${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

echo "setup.sh: $QUESTION_ID ready"
