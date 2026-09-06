#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q104-42-blue-green-secret-config-cutover${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
kind: Secret
metadata:
  name: app-config-blue
  labels:
    clusterdrill-question: $QUESTION_ID
stringData:
  FEATURE_FLAG: "off"
---
apiVersion: v1
kind: Secret
metadata:
  name: app-config-green
  labels:
    clusterdrill-question: $QUESTION_ID
stringData:
  FEATURE_FLAG: "on"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: billing-blue
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 3
  selector:
    matchLabels:
      app: billing
      version: blue
  template:
    metadata:
      labels:
        app: billing
        version: blue
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        # Explicit, small resources: two 3-replica Deployments at the
        # LimitRange's default 128Mi/container is 768Mi of limits.memory,
        # over the namespace ResourceQuota's 640Mi cap.
        - name: billing
          image: nginx:1.24-alpine
          resources:
            requests:
              cpu: 10m
              memory: 16Mi
            limits:
              cpu: 50m
              memory: 32Mi
          envFrom:
            - secretRef:
                name: app-config-blue
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: billing-green
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 3
  selector:
    matchLabels:
      app: billing
      version: green
  template:
    metadata:
      labels:
        app: billing
        version: green
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: billing
          image: nginx:1.25-alpine
          resources:
            requests:
              cpu: 10m
              memory: 16Mi
            limits:
              cpu: 50m
              memory: 32Mi
          envFrom:
            # Bug: this should reference app-config-green, left over from
            # cloning billing-blue's manifest. Part of the candidate's task
            # is to notice and fix this before the cutover.
            - secretRef:
                name: app-config-blue
---
apiVersion: v1
kind: Service
metadata:
  name: billing-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: billing
    version: blue
  ports:
    - port: 80
      targetPort: 80
EOF

kubectl rollout status deployment/billing-blue -n "$QUESTION_ID" --timeout=60s || true
kubectl rollout status deployment/billing-green -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
