#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q113-19-service-down-three-faults${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: orders
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 2
  selector:
    matchLabels:
      app: orders
  template:
    metadata:
      labels:
        app: orders
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: orders
          image: nginx:1.27
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: client
  labels:
    app: client
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: client
      image: busybox:1.36
      command: ["sleep", "3600"]
---
apiVersion: v1
kind: Service
metadata:
  name: orders-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: order
  ports:
    - port: 80
      targetPort: 8080
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  podSelector: {}
  policyTypes: ["Ingress"]
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-client
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  podSelector:
    matchLabels:
      app: orders
  policyTypes: ["Ingress"]
  ingress:
    - from:
        - podSelector:
            matchLabels:
              role: client
      ports:
        - protocol: TCP
          port: 80
EOF

kubectl wait --for=condition=Available deployment/orders -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
