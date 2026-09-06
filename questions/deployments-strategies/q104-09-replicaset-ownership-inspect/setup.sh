#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q104-09-replicaset-ownership-inspect${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: sessions
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 3
  selector:
    matchLabels:
      app: sessions
  template:
    metadata:
      labels:
        app: sessions
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: sessions
          image: nginx:1.24-alpine
EOF
kubectl rollout status deployment/sessions -n "$QUESTION_ID" --timeout=60s || true

# Roll once more so an old, scaled-to-0 ReplicaSet exists alongside the
# active one - the candidate has to pick the right one, not just "any RS".
kubectl set image deployment/sessions sessions=nginx:1.25-alpine -n "$QUESTION_ID"
kubectl rollout status deployment/sessions -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
