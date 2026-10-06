#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q114-18-rotate-a-secret-watch-it-land${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl create secret generic api-token -n "$QUESTION_ID" \
  --from-literal=value=v1 \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label secret api-token -n "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: audit
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
  name: api
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
        clusterdrill-question: $QUESTION_ID
    spec:
      volumes:
        - name: token
          secret:
            secretName: api-token
        - name: audit
          persistentVolumeClaim:
            claimName: audit
      containers:
        - name: api
          image: busybox:1.36
          env:
            - name: TOKEN
              valueFrom:
                secretKeyRef:
                  name: api-token
                  key: value
          command: ["sh", "-c", "while true; do echo env=\$TOKEN file=\$(cat /etc/token/value) >> /audit/log; sleep 5; done"]
          volumeMounts:
            - name: token
              mountPath: /etc/token
              readOnly: true
            - name: audit
              mountPath: /audit
EOF

kubectl rollout status deployment/api -n "$QUESTION_ID" --timeout=60s
# Give the loop a moment to write at least one pre-rotation line, so the
# "accumulated across rotation and restart" check has something real from
# before the candidate even starts.
sleep 6

echo "setup.sh: $QUESTION_ID ready"
