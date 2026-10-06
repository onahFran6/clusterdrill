#!/usr/bin/env bash
# Idempotent: creates/resets the namespace and seeds six Pods with mixed
# labels for the candidate to query/relabel - a lightweight pause image
# since none of these Pods need to actually do anything.
set -euo pipefail

QUESTION_ID="q112-18-selecting-pods-by-label${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

IMG=registry.k8s.io/pause:3.9
kubectl run web-1   --image="$IMG" -n "$QUESTION_ID" --labels=env=prod,tier=web,temp=yes,clusterdrill-question="$QUESTION_ID"
kubectl run web-2   --image="$IMG" -n "$QUESTION_ID" --labels=env=staging,tier=web,clusterdrill-question="$QUESTION_ID"
kubectl run api-1   --image="$IMG" -n "$QUESTION_ID" --labels=env=prod,tier=api,temp=yes,clusterdrill-question="$QUESTION_ID"
kubectl run db-1    --image="$IMG" -n "$QUESTION_ID" --labels=env=prod,tier=db,clusterdrill-question="$QUESTION_ID"
kubectl run cache-1 --image="$IMG" -n "$QUESTION_ID" --labels=env=prod,tier=cache,clusterdrill-question="$QUESTION_ID"
kubectl run batch-1 --image="$IMG" -n "$QUESTION_ID" --labels=env=prod,temp=yes,clusterdrill-question="$QUESTION_ID"

echo "setup.sh: $QUESTION_ID ready"
