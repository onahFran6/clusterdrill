#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q113-13-ingress-three-faults${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: portal
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 2
  selector:
    matchLabels:
      app: portal
  template:
    metadata:
      labels:
        app: portal
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: portal
          image: nginx:1.27
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: portal-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: portal
  ports:
    - port: 80
      targetPort: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: portal
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  rules:
    - host: portal.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: portal-service
                port:
                  number: 8080
EOF

kubectl wait --for=condition=Available deployment/portal -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
