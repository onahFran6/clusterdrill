#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q116-01-exact-or-prefix${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: docs
  labels:
    app: docs
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: docs
  template:
    metadata:
      labels:
        app: docs
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: docs
          image: hashicorp/http-echo:1.0
          args: ["-listen=:5678", "-text=docs"]
          ports:
            - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: docs-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: docs
  ports:
    - port: 80
      targetPort: 5678
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: home
  labels:
    app: home
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: home
  template:
    metadata:
      labels:
        app: home
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: home
          image: hashicorp/http-echo:1.0
          args: ["-listen=:5678", "-text=home"]
          ports:
            - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: home-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: home
  ports:
    - port: 80
      targetPort: 5678
EOF

kubectl wait --for=condition=Available deployment/docs -n "$QUESTION_ID" --timeout=90s || true
kubectl wait --for=condition=Available deployment/home -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
