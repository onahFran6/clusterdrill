#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q111-04-rollingupdate-bounds-and-one-revision${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: relay
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 10
  selector:
    matchLabels:
      app: relay
  template:
    metadata:
      labels:
        app: relay
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: nginx
          image: nginx:1.25
EOF

kubectl rollout status deployment/relay -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
