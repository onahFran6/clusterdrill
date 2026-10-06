#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q111-10-three-faults-zero-pods${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: report-config
  labels:
    clusterdrill-question: $QUESTION_ID
data:
  MODE: batch
---
apiVersion: v1
kind: Secret
metadata:
  name: report-secret
  labels:
    clusterdrill-question: $QUESTION_ID
stringData:
  token: abc123
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: reporter
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 2
  selector:
    matchLabels:
      app: reporter
  template:
    metadata:
      labels:
        app: reporter
        clusterdrill-question: $QUESTION_ID
    spec:
      serviceAccountName: reporter-sa
      containers:
        - name: reporter
          image: busybox:1.36
          command: ["sh", "-c", "sleep 3600"]
          envFrom:
            - configMapRef:
                name: reports-config
          env:
            - name: TOKEN
              valueFrom:
                secretKeyRef:
                  name: report-secret
                  key: TOKEN
EOF

echo "setup.sh: $QUESTION_ID ready"
