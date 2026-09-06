#!/usr/bin/env bash
# Idempotent: creates/resets namespace q105-18-secret-volume-default-mode
# and seeds the Secret plus starting pod. Every cluster object created here
# carries the label clusterdrill-question=q105-18-secret-volume-default-mode
#.

set -euo pipefail

QUESTION_ID="q105-18-secret-volume-default-mode${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: ssh-key
  labels:
    clusterdrill-question: $QUESTION_ID
stringData:
  id_rsa: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    placeholder-not-a-real-key
    -----END OPENSSH PRIVATE KEY-----
---
apiVersion: v1
kind: Pod
metadata:
  name: deploy-agent
  labels:
    app: deploy-agent
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: deploy-agent
      image: nginx:1.25-alpine
EOF

kubectl wait --for=condition=Ready pod/deploy-agent -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
