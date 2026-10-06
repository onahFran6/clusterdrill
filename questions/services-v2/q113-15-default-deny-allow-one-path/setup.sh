#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q113-15-default-deny-allow-one-path${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: backend
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: backend
          image: nginx:1.27
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: backend-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: backend
  ports:
    - port: 80
      targetPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: frontend
  labels:
    app: frontend
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: frontend
      image: busybox:1.36
      command: ["sleep", "3600"]
---
apiVersion: v1
kind: Pod
metadata:
  name: intruder
  labels:
    app: intruder
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: intruder
      image: busybox:1.36
      command: ["sleep", "3600"]
EOF

kubectl wait --for=condition=Available deployment/backend -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
