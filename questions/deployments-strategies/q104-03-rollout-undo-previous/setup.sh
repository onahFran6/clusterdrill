#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q104-03-rollout-undo-previous${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: search
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 3
  selector:
    matchLabels:
      app: search
  template:
    metadata:
      labels:
        app: search
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: search
          image: nginx:1.24-alpine
EOF

kubectl rollout status deployment/search -n "$QUESTION_ID" --timeout=60s || true

# Revision 2: a broken image that will never become ready. This intentionally
# leaves the Deployment stuck mid-rollout - the candidate must undo it.
kubectl set image deployment/search search=nginx:1.25-alpine-does-not-exist -n "$QUESTION_ID"
kubectl rollout status deployment/search -n "$QUESTION_ID" --timeout=15s || true

echo "setup.sh: $QUESTION_ID ready"
