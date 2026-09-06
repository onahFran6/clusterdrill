#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q109-19-projected-volume-secret-downwardapi${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl create secret generic api-creds \
  --from-literal=token=s3cr3t \
  -n "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label secret api-creds "clusterdrill-question=$QUESTION_ID" -n "$QUESTION_ID" --overwrite

echo "setup.sh: $QUESTION_ID ready"
