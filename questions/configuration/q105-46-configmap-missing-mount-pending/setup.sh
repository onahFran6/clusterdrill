#!/usr/bin/env bash
# Idempotent: creates/resets namespace
# q105-46-configmap-missing-mount-pending and seeds a Deployment whose pod
# template references a ConfigMap volume ('settings-config') that does not
# exist yet - the pod sticks in ContainerCreating/Pending with a
# FailedMount event until the candidate creates it. Every cluster object
# created here carries the label
# clusterdrill-question=q105-46-configmap-missing-mount-pending
#.

set -euo pipefail

QUESTION_ID="q105-46-configmap-missing-mount-pending${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: report-generator
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: report-generator
  template:
    metadata:
      labels:
        app: report-generator
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: report-generator
          image: nginx:1.25-alpine
          volumeMounts:
            - name: settings-vol
              mountPath: /etc/report-settings
      volumes:
        - name: settings-vol
          configMap:
            name: settings-config
EOF

# Intentionally not waiting for rollout here - the pod is expected to sit
# unable to mount until the candidate creates settings-config.

echo "setup.sh: $QUESTION_ID ready"
