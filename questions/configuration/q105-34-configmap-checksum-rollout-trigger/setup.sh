#!/usr/bin/env bash
# Idempotent: creates/resets namespace
# q105-34-configmap-checksum-rollout-trigger and seeds:
#   - ConfigMap app-config (key GREETING)
#   - Deployment worker (2 replicas) whose pod template mounts app-config
#     as a volume at /etc/app, and whose container copies
#     /etc/app/GREETING to /var/run/baked-greeting ONCE at container
#     startup (simulating an app that bakes config into memory rather than
#     re-reading the live-synced mount).
#   - a pod template annotation checksum/config holding the sha256 of
#     app-config's data AT THE TIME the Deployment was created (hello-v1)
#   - a follow-up ConfigMap update to hello-v2 that intentionally does NOT
#     touch the Deployment, so the stored checksum annotation goes stale
#     and no rollout is triggered - reproducing "someone edited the
#     ConfigMap but the pods never restarted".
# Every cluster object created here carries the label
# clusterdrill-question=q105-34-configmap-checksum-rollout-trigger
#.

set -euo pipefail

QUESTION_ID="q105-34-configmap-checksum-rollout-trigger${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# Step 1: ConfigMap at its original value.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  labels:
    clusterdrill-question: $QUESTION_ID
data:
  GREETING: "hello-v1"
EOF

# Checksum of the ConfigMap's data AS IT IS RIGHT NOW (hello-v1) - this is
# what a correctly-wired checksum annotation would hold at deploy time.
_checksum_v1="$(kubectl get configmap app-config -n "$QUESTION_ID" -o jsonpath='{.data}' | sha256sum | awk '{print $1}')"

# Step 2: Deployment whose pod template carries that (currently correct)
# checksum annotation.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
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
      annotations:
        checksum/config: "$_checksum_v1"
    spec:
      containers:
        - name: worker
          image: busybox:1.36
          command: ["sh", "-c", "cp /etc/app/GREETING /var/run/baked-greeting; sleep 3600"]
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
            name: app-config
EOF

kubectl rollout status deployment/worker -n "$QUESTION_ID" --timeout=60s || true

# Step 3: someone updates the ConfigMap's data, but nobody recomputes the
# checksum annotation or restarts the Deployment - the running pods keep
# serving hello-v1 baked in at their last startup.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  labels:
    clusterdrill-question: $QUESTION_ID
data:
  GREETING: "hello-v2"
EOF

echo "setup.sh: $QUESTION_ID ready"
