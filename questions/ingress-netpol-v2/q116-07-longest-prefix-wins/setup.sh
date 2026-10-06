#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q116-07-longest-prefix-wins${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: v1
  labels:
    app: v1
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: v1
  template:
    metadata:
      labels:
        app: v1
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: v1
          image: hashicorp/http-echo:1.0
          args: ["-listen=:5678", "-text=v1"]
          ports:
            - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: v1-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: v1
  ports:
    - port: 80
      targetPort: 5678
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: v2
  labels:
    app: v2
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: v2
  template:
    metadata:
      labels:
        app: v2
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: v2
          image: hashicorp/http-echo:1.0
          args: ["-listen=:5678", "-text=v2"]
          ports:
            - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: v2-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: v2
  ports:
    - port: 80
      targetPort: 5678
EOF

kubectl wait --for=condition=Available deployment/v1 -n "$QUESTION_ID" --timeout=90s || true
kubectl wait --for=condition=Available deployment/v2 -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
