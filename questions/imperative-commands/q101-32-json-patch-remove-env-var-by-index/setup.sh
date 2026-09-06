#!/usr/bin/env bash
# Idempotent: creates/resets namespace q101-32-json-patch-remove-env-var-by-index
# and seeds a running pod 'api-worker' with five ordered env vars, one of
# which (LEGACY_API_URL, index 2) the candidate must remove entirely via a
# JSON Patch remove-by-index, without disturbing the other four.

set -euo pipefail

QUESTION_ID="q101-32-json-patch-remove-env-var-by-index${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# Recreate the pod each run so its env list always starts in the exact
# known five-var order the check.sh (and the task) describe.
kubectl delete pod api-worker -n "$QUESTION_ID" --ignore-not-found >/dev/null 2>&1
kubectl wait --for=delete pod/api-worker -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1 || true

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: api-worker
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: api-worker
      image: busybox:1.36
      command: ["sleep", "3600"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
      env:
        - name: APP_ENV
          value: "production"
        - name: LOG_LEVEL
          value: "info"
        - name: LEGACY_API_URL
          value: "http://old-api.internal:8080"
        - name: MAX_RETRIES
          value: "5"
        - name: CACHE_TTL
          value: "300"
EOF

kubectl wait --for=condition=Ready pod/api-worker -n "$QUESTION_ID" --timeout=60s

echo "setup.sh: $QUESTION_ID ready"
