#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q116-06-route-by-port-name${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: app
  labels:
    app: app
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app
  template:
    metadata:
      labels:
        app: app
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: app
          image: hashicorp/http-echo:1.0
          args: ["-listen=:5678", "-text=app"]
          ports:
            - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: app-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: app
  ports:
    - port: 80
      targetPort: 5678
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: health
  labels:
    app: health
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: health
  template:
    metadata:
      labels:
        app: health
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: health
          image: hashicorp/http-echo:1.0
          args: ["-listen=:5678", "-text=health"]
          ports:
            - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: health-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: health
  ports:
    - port: 80
      targetPort: 5678
EOF

kubectl wait --for=condition=Available deployment/app -n "$QUESTION_ID" --timeout=90s || true
kubectl wait --for=condition=Available deployment/health -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
