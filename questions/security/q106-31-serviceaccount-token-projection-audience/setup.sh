#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds a ServiceAccount + Pod that
# uses only the default automounted SA token (no custom projected volume).
set -euo pipefail

QUESTION_ID="q106-31-serviceaccount-token-projection-audience${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
kind: ServiceAccount
metadata:
  name: vault-client
  labels:
    clusterdrill-question: $QUESTION_ID
EOF

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: secrets-agent
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  serviceAccountName: vault-client
  containers:
    - name: secrets-agent
      image: busybox:1.36
      command: ["sleep", "3600"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
EOF

kubectl wait --for=condition=Ready pod/secrets-agent -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
