#!/usr/bin/env bash
# Idempotent: creates/resets namespace and applies a 3-container Pod where
# only the MIDDLE container ('cache') has a misconfigured readinessProbe
# (wrong port) - 'frontend' and 'logger' have no readinessProbe at all
# (ready once Running, by default) and are both fine. Overall Pod readiness
# requires every container Ready, so the candidate must identify which ONE
# of the three is actually the problem, not assume it's the first.

set -euo pipefail

QUESTION_ID="q107-50-multi-container-one-container-gates-readiness${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: web-stack
  labels:
    app: web-stack
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: frontend
      image: nginx:1.25-alpine
    - name: cache
      image: nginx:1.25-alpine
      readinessProbe:
        httpGet:
          path: /
          port: 8888
        periodSeconds: 2
    - name: logger
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
EOF

sleep 15

echo "setup.sh: $QUESTION_ID ready (frontend and logger are individually fine - 'cache' is the one blocking overall Pod readiness)"
