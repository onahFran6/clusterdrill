#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q113-11-ingress-path-routing${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

for a in shop api; do
  kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $a
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $a
  template:
    metadata:
      labels:
        app: $a
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: $a
          image: busybox:1.36
          command: ["sh", "-c", "mkdir -p /www && echo $a-ok > /www/index.html && httpd -f -p 80 -h /www"]
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: $a-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: $a
  ports:
    - port: 80
      targetPort: 80
EOF
done

kubectl wait --for=condition=Available deployment/shop -n "$QUESTION_ID" --timeout=90s || true
kubectl wait --for=condition=Available deployment/api -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
