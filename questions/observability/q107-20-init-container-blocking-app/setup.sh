#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q107-20-init-container-blocking-app${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# Seed a pod whose init container loops forever waiting for a Service that
# does not exist yet - it stays in "Init:0/1" and the main container never
# starts, until the candidate creates the Service and labels the pod so it
# becomes a matching endpoint.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: report-gen
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  initContainers:
    - name: wait-for-config
      image: busybox:1.36
      command:
        - sh
        - -c
        - until nslookup config-svc.$QUESTION_ID.svc.cluster.local; do sleep 2; done
  containers:
    - name: app
      image: nginx:1.25-alpine
EOF

echo "setup.sh: $QUESTION_ID ready"
