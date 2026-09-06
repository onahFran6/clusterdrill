#!/usr/bin/env bash
# Idempotent: creates/resets namespace
# q105-29-immutable-configmap-rollout-swap and seeds an immutable
# ConfigMap app-config-v1 (LOG_LEVEL=info) plus a running Deployment
# 'worker' that mounts it as a volume at /etc/app. Every cluster object
# created here carries the label
# clusterdrill-question=q105-29-immutable-configmap-rollout-swap
#.

set -euo pipefail

QUESTION_ID="q105-29-immutable-configmap-rollout-swap${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: app-config-v1
  labels:
    clusterdrill-question: $QUESTION_ID
data:
  LOG_LEVEL: "info"
immutable: true
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: worker
  labels:
    app: worker
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 2
  selector:
    matchLabels:
      app: worker
  template:
    metadata:
      labels:
        app: worker
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: worker
          image: busybox:1.36
          command: ["sleep", "3600"]
          resources:
            requests:
              cpu: "25m"
              memory: "32Mi"
            limits:
              cpu: "50m"
              memory: "64Mi"
          volumeMounts:
            - name: app-config
              mountPath: /etc/app
      volumes:
        - name: app-config
          configMap:
            name: app-config-v1
EOF

kubectl rollout status deployment/worker -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
