#!/usr/bin/env bash
# Idempotent: creates/resets namespace and applies a Pod whose startupProbe
# checks a path nginx returns 404 for. Until startupProbe succeeds,
# kubelet never even starts running livenessProbe/readinessProbe - the Pod just sits "not started" forever, not
# crash-looping (failureThreshold is generous), so this apply succeeds and
# the container itself stays up the whole time.

set -euo pipefail

QUESTION_ID="q107-38-startupprobe-never-succeeds-blocks-liveness${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: slow-starter
  labels:
    app: slow-starter
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: slow-starter
      image: nginx:1.25-alpine
      startupProbe:
        httpGet:
          path: /this-path-does-not-exist
          port: 80
        periodSeconds: 2
        failureThreshold: 100
      livenessProbe:
        httpGet:
          path: /
          port: 80
        periodSeconds: 2
      readinessProbe:
        httpGet:
          path: /
          port: 80
        periodSeconds: 2
EOF

sleep 10

echo "setup.sh: $QUESTION_ID ready (slow-starter Running but stuck 'not started' - startupProbe never succeeds)"
