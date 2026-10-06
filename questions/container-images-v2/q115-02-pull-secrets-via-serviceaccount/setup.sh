#!/usr/bin/env bash
# Idempotent: creates/resets the namespace and seeds ServiceAccount 'builder'.
# The Secret, the ServiceAccount patch and Pod 'app' are all built by the
# candidate.
set -euo pipefail

QUESTION_ID="q115-02-pull-secrets-via-serviceaccount${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl create serviceaccount builder -n "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label serviceaccount builder -n "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite

echo "setup.sh: $QUESTION_ID ready"
