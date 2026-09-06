#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q108-18-service-named-target-port${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: image-resizer
  labels:
    app: image-resizer
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 2
  selector:
    matchLabels:
      app: image-resizer
  template:
    metadata:
      labels:
        app: image-resizer
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: image-resizer
          image: httpd:2.4-alpine
          ports:
            - name: worker-port
              containerPort: 8081
EOF

kubectl wait --for=condition=Available deployment/image-resizer -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
