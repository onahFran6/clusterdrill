#!/usr/bin/env bash
# Idempotent: creates/resets namespace
# q105-16-configmap-projected-volume-live-update and seeds the ConfigMap
# plus a pod that already mounts it via a projected volume. Every cluster
# object created here carries the label
# clusterdrill-question=q105-16-configmap-projected-volume-live-update
#.

set -euo pipefail

QUESTION_ID="q105-16-configmap-projected-volume-live-update${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
kind: ConfigMap
metadata:
  name: banner-config
  labels:
    clusterdrill-question: $QUESTION_ID
data:
  banner.txt: v1-original
---
apiVersion: v1
kind: Pod
metadata:
  name: banner-app
  labels:
    app: banner-app
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: banner-app
      image: nginx:1.25-alpine
      volumeMounts:
        - name: banner
          mountPath: /etc/banner
  volumes:
    - name: banner
      projected:
        sources:
          - configMap:
              name: banner-config
EOF

kubectl wait --for=condition=Ready pod/banner-app -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
