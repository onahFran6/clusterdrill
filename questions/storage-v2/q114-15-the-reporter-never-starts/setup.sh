#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q114-15-the-reporter-never-starts${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: reports
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  storageClassName: q114-15-fast-ssd
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 100Mi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: reporter
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: reporter
  template:
    metadata:
      labels:
        app: reporter
        clusterdrill-question: $QUESTION_ID
    spec:
      volumes:
        - name: out
          persistentVolumeClaim:
            claimName: report
      containers:
        - name: r
          image: busybox:1.36
          command: ["sleep", "3600"]
          volumeMounts:
            - name: out
              mountPath: /out
EOF

echo "setup.sh: $QUESTION_ID ready"
