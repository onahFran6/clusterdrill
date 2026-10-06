#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q114-11-seed-once-keep-edits${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl create configmap site-seed -n "$QUESTION_ID" \
  --from-literal=index.html='seeded from configmap' \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label configmap site-seed -n "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite

echo "setup.sh: $QUESTION_ID ready"
