#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q116-12-internet-yes-cluster-and-metadata-no${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: inside
  labels:
    app: inside
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: inside
  template:
    metadata:
      labels:
        app: inside
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: inside
          image: hashicorp/http-echo:1.0
          args: ["-listen=:5678", "-text=inside"]
          ports:
            - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: inside-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: inside
  ports:
    - port: 80
      targetPort: 5678
---
apiVersion: v1
kind: Pod
metadata:
  name: fetcher
  labels:
    app: fetcher
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: fetcher
      image: busybox:1.36
      command: ["sleep", "3600"]
EOF

kubectl wait --for=condition=Available deployment/inside -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
