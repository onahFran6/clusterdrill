#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q114-20-move-to-a-bigger-claim${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: old-data
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
  name: archive
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: archive
  template:
    metadata:
      labels:
        app: archive
        clusterdrill-question: $QUESTION_ID
    spec:
      volumes:
        - name: d
          persistentVolumeClaim:
            claimName: old-data
      containers:
        - name: a
          image: busybox:1.36
          command: ["sh", "-c", "for i in 1 2 3; do echo record \$i > /archive/r\$i; done; sleep 3600"]
          volumeMounts:
            - name: d
              mountPath: /archive
EOF

kubectl rollout status deployment/archive -n "$QUESTION_ID" --timeout=60s

echo "setup.sh: $QUESTION_ID ready"
