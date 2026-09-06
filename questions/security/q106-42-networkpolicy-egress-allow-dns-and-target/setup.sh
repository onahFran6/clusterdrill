#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q106-42-networkpolicy-egress-allow-dns-and-target${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
kind: Pod
metadata:
  name: report-generator
  labels:
    app: report-generator
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: report-generator
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
---
apiVersion: v1
kind: Pod
metadata:
  name: data-store
  labels:
    app: data-store
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: data-store
      image: nginx:1.25-alpine
      ports:
        - containerPort: 80
EOF

kubectl wait --for=condition=Ready pod/report-generator -n "$QUESTION_ID" --timeout=60s || true
kubectl wait --for=condition=Ready pod/data-store -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready (no NetworkPolicy exists yet - candidate creates it)"
