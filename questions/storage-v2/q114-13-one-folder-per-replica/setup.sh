#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q114-13-one-folder-per-replica${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
kind: PersistentVolumeClaim
metadata:
  name: logs
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 100Mi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: logger
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 3
  selector:
    matchLabels:
      app: logger
  template:
    metadata:
      labels:
        app: logger
        clusterdrill-question: $QUESTION_ID
    spec:
      volumes:
        - name: logs
          persistentVolumeClaim:
            claimName: logs
      containers:
        - name: logger
          image: busybox:1.36
          command: ["sh", "-c", "while true; do echo \$(hostname) \$(date) >> /logs/app.log; sleep 5; done"]
          volumeMounts:
            - name: logs
              mountPath: /logs
EOF

kubectl rollout status deployment/logger -n "$QUESTION_ID" --timeout=60s

echo "setup.sh: $QUESTION_ID ready"
