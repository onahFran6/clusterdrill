#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q116-08-two-hosts-two-certificates${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: alpha
  labels:
    app: alpha
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: alpha
  template:
    metadata:
      labels:
        app: alpha
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: alpha
          image: hashicorp/http-echo:1.0
          args: ["-listen=:5678", "-text=alpha"]
          ports:
            - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: alpha-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: alpha
  ports:
    - port: 80
      targetPort: 5678
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: beta
  labels:
    app: beta
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: beta
  template:
    metadata:
      labels:
        app: beta
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: beta
          image: hashicorp/http-echo:1.0
          args: ["-listen=:5678", "-text=beta"]
          ports:
            - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: beta-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: beta
  ports:
    - port: 80
      targetPort: 5678
EOF

kubectl wait --for=condition=Available deployment/alpha -n "$QUESTION_ID" --timeout=90s || true
kubectl wait --for=condition=Available deployment/beta -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
