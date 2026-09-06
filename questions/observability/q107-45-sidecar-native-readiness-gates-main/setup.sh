#!/usr/bin/env bash
# Idempotent: creates/resets namespace and applies a Pod with a native
# sidecar (an init container with restartPolicy: Always, GA since 1.29)
# whose OWN readinessProbe is misconfigured (wrong port). The main
# container is healthy and Ready on its own, but overall Pod readiness
# requires every container - including restartPolicy:Always init
# containers - to be Ready, so the Pod as a whole never reaches Ready.

set -euo pipefail

QUESTION_ID="q107-45-sidecar-native-readiness-gates-main${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: metrics-app
  labels:
    app: metrics-app
    clusterdrill-question: $QUESTION_ID
spec:
  initContainers:
    - name: metrics-sidecar
      image: nginx:1.25-alpine
      restartPolicy: Always
      readinessProbe:
        httpGet:
          path: /
          port: 9999
        periodSeconds: 2
        failureThreshold: 3
  containers:
    - name: metrics-app
      image: nginx:1.25-alpine
EOF

sleep 15

echo "setup.sh: $QUESTION_ID ready (metrics-app container is healthy, but the Pod overall is not Ready - metrics-sidecar's own readinessProbe targets the wrong port)"
