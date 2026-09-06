#!/usr/bin/env bash
# Idempotent: creates/resets namespace
# q101-49-rollout-restart-stale-secret-values and seeds a Secret, a
# Deployment whose container reads that Secret via env
# valueFrom.secretKeyRef, waits for the pod to actually start (so its env is
# resolved from the OLD secret value), then rotates the Secret's value -
# simulating a credential rotation the running pod never sees, since env
# vars sourced from a Secret are only read once at container start.

set -euo pipefail

QUESTION_ID="q101-49-rollout-restart-stale-secret-values${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl create secret generic billing-creds \
  -n "$QUESTION_ID" \
  --from-literal=API_TOKEN=old-token-value \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label secret billing-creds -n "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: billing-sync
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: billing-sync
  template:
    metadata:
      labels:
        app: billing-sync
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: billing-sync
          image: busybox:1.36
          command: ["sleep", "3600"]
          env:
            - name: API_TOKEN
              valueFrom:
                secretKeyRef:
                  name: billing-creds
                  key: API_TOKEN
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
EOF

kubectl rollout status deployment/billing-sync -n "$QUESTION_ID" --timeout=60s || true

# Rotate the secret's value AFTER the pod already resolved the old one -
# the running pod's env stays stale until something forces a new pod.
kubectl create secret generic billing-creds \
  -n "$QUESTION_ID" \
  --from-literal=API_TOKEN=rotated-token-value \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label secret billing-creds -n "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite

echo "setup.sh: $QUESTION_ID ready"
