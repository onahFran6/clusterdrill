#!/usr/bin/env bash
# Idempotent: creates/resets namespace q102-46-ambassador-dependent-env-var-order
# and seeds a BROKEN Pod. "ambassador" composes its upstream target address
# from two other env vars using $(VAR) dependent-variable syntax:
# TARGET_ADDR: "$(BACKEND_HOST):$(BACKEND_PORT)". Kubernetes only expands a
# $(VAR) reference if VAR was already defined EARLIER in the SAME
# container's env list - here TARGET_ADDR is listed FIRST, before
# BACKEND_HOST and BACKEND_PORT are defined, so neither reference expands:
# TARGET_ADDR ends up holding the literal, unexpanded string
# "$(BACKEND_HOST):$(BACKEND_PORT)" instead of "primary-api:9090". Nothing
# crashes - "ambassador" just writes the wrong (unexpanded) value.
set -euo pipefail

QUESTION_ID="q102-46-ambassador-dependent-env-var-order${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl apply -n "$QUESTION_ID" -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: ambassador-target
  labels:
    clusterdrill-question: q102-46-ambassador-dependent-env-var-order
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh", "-c", "while true; do sleep 3600; done"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
    - name: ambassador
      image: busybox:1.36
      command: ["sh", "-c", "mkdir -p /report; echo \"$TARGET_ADDR\" > /report/target.txt; while true; do sleep 3600; done"]
      env:
        - name: TARGET_ADDR
          value: "$(BACKEND_HOST):$(BACKEND_PORT)"
        - name: BACKEND_HOST
          value: primary-api
        - name: BACKEND_PORT
          value: "9090"
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
EOF

echo "setup.sh: q102-46-ambassador-dependent-env-var-order ready"
