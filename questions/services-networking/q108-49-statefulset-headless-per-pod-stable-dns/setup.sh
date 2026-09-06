#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q108-49-statefulset-headless-per-pod-stable-dns${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
kind: Service
metadata:
  name: db-cluster
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  clusterIP: None
  selector:
    app: db-cluster
  ports:
    - port: 5432
      targetPort: 5432
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: db-cluster
  labels:
    app: db-cluster
    clusterdrill-question: $QUESTION_ID
spec:
  serviceName: db-cluster-svc
  replicas: 2
  selector:
    matchLabels:
      app: db-cluster
  template:
    metadata:
      labels:
        app: db-cluster
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: db-cluster
          image: busybox:1.36
          command: ["sh", "-c", "sleep 3600"]
          ports:
            - containerPort: 5432
EOF

# The StatefulSet's pods still come up fine even with the wrong serviceName
# (only per-pod DNS registration is affected), so this wait is expected to
# succeed despite the bug.
kubectl wait --for=condition=Ready pod/db-cluster-0 -n "$QUESTION_ID" --timeout=90s || true
kubectl wait --for=condition=Ready pod/db-cluster-1 -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
