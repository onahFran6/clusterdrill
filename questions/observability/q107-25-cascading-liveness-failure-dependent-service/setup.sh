#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds a ConfigMap + a pod whose
# container references a ConfigMap key that does not exist, guaranteeing
# CreateContainerConfigError -> CrashLoopBackOff before the container (and
# its livenessProbe) ever gets a chance to run.
set -euo pipefail

QUESTION_ID="q107-25-cascading-liveness-failure-dependent-service${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: orders-config
  labels:
    clusterdrill-question: $QUESTION_ID
data:
  PORT: "8080"
---
apiVersion: v1
kind: Pod
metadata:
  name: orders-api
  labels:
    app: orders-api
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: orders-api
      image: busybox:1.36
      command:
        - sh
        - -c
        - 'PORT=\${LISTEN_PORT:-0}; if [ "\$PORT" = "0" ]; then exit 1; fi; httpd -f -p \$PORT -h /tmp 2>&1'
      env:
        - name: LISTEN_PORT
          valueFrom:
            configMapKeyRef:
              name: orders-config
              key: LISTEN_PORT
      livenessProbe:
        tcpSocket:
          port: 8080
        initialDelaySeconds: 3
        periodSeconds: 5
EOF

echo "setup.sh: $QUESTION_ID ready (pod will enter CrashLoopBackOff: missing ConfigMap key LISTEN_PORT)"
