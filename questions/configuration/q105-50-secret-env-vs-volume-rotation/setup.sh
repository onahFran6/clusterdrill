#!/usr/bin/env bash
# Idempotent: creates/resets namespace q105-50-secret-env-vs-volume-rotation
# and seeds the starting Secret and two-container pod. Every cluster object
# created here carries the label
# clusterdrill-question=q105-50-secret-env-vs-volume-rotation
#.

set -euo pipefail

QUESTION_ID="q105-50-secret-env-vs-volume-rotation${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: db-creds
  labels:
    clusterdrill-question: $QUESTION_ID
stringData:
  PASSWORD: initial-pw
EOF

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: credential-consumer
  labels:
    app: credential-consumer
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: env-reader
      image: busybox:1.36
      command: ["sleep", "3600"]
      env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-creds
              key: PASSWORD
    - name: vol-reader
      image: busybox:1.36
      command: ["sleep", "3600"]
      volumeMounts:
        - name: secret-vol
          mountPath: /etc/secret
  volumes:
    - name: secret-vol
      secret:
        secretName: db-creds
EOF

kubectl wait --for=condition=Ready pod/credential-consumer -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
