#!/usr/bin/env bash
# Idempotent: creates/resets namespace q102-32-sidecar-secret-env-typo and
# seeds a Secret plus a BROKEN two-container Pod. The Secret "api-credentials"
# really exists with key API_TOKEN, but the "reporter" sidecar's
# envFrom[0].secretRef.name is typo'd to "api-credential" (missing the
# trailing "s"). Kubernetes will not start a container whose envFrom
# references a Secret that does not exist (unless secretRef.optional is
# true, which it is not here), so "reporter" never runs its command at all -
# it sits waiting with reason CreateContainerConfigError while "app" (the
# unrelated main container) keeps running fine. kubectl get pod shows 1/2.
set -euo pipefail

QUESTION_ID="q102-32-sidecar-secret-env-typo${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: api-credentials
  labels:
    clusterdrill-question: $QUESTION_ID
type: Opaque
stringData:
  API_TOKEN: sample-reporter-token
EOF

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: token-reporter
  labels:
    clusterdrill-question: $QUESTION_ID
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
    - name: reporter
      image: busybox:1.36
      command: ["sh", "-c", "mkdir -p /report; while true; do echo \"\${API_TOKEN:-MISSING_TOKEN}\" > /report/status.txt; sleep 5; done"]
      envFrom:
        - secretRef:
            name: api-credential
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
EOF

echo "setup.sh: $QUESTION_ID ready"
