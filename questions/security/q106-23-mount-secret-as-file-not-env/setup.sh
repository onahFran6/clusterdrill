#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds a Secret only - the Pod that
# mounts it is left for the candidate to create.

set -euo pipefail

QUESTION_ID="q106-23-mount-secret-as-file-not-env${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: tls-cert
  labels:
    clusterdrill-question: $QUESTION_ID
stringData:
  tls.crt: dummy-cert-content
  tls.key: dummy-key-content
EOF

echo "setup.sh: $QUESTION_ID ready"
