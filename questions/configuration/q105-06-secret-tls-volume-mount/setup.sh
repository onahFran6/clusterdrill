#!/usr/bin/env bash
# Idempotent: creates/resets namespace q105-06-secret-tls-volume-mount,
# generates a throwaway self-signed cert/key pair under /tmp, and seeds the
# starting pod. Every cluster object created here carries the label
# clusterdrill-question=q105-06-secret-tls-volume-mount.

set -euo pipefail

QUESTION_ID="q105-06-secret-tls-volume-mount${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# Throwaway self-signed cert/key for practice only - not a cluster object,
# so it carries no label. Written into this question's own terminal working
# directory (not shared /tmp) - see question_workdir() in lib/grading.sh.
WORK_DIR="$(question_workdir "$QUESTION_ID")"
openssl req -x509 -newkey rsa:2048 \
  -keyout "$WORK_DIR/q105-06-tls.key" -out "$WORK_DIR/q105-06-tls.crt" \
  -days 365 -nodes -subj "/CN=q105-06.example.internal" >/dev/null 2>&1

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: edge-proxy
  labels:
    app: edge-proxy
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: edge-proxy
      image: nginx:1.25-alpine
EOF

kubectl wait --for=condition=Ready pod/edge-proxy -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
