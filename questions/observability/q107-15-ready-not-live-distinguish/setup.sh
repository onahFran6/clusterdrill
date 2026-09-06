#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q107-15-ready-not-live-distinguish${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: search-svc
  labels:
    app: search-svc
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: search-svc
      image: nginx:1.25-alpine
      ports:
        - containerPort: 80
      livenessProbe:
        httpGet:
          path: /
          port: 80
        periodSeconds: 5
      readinessProbe:
        httpGet:
          path: /does-not-exist
          port: 80
        periodSeconds: 5
        failureThreshold: 2
EOF

# Give the readiness probe time to fail at least once so the pod settles
# into the "Running but NotReady" state before the candidate starts.
sleep 15

echo "setup.sh: $QUESTION_ID ready"
