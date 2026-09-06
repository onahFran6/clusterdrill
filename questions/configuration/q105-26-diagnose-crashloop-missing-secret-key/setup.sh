#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds a Secret 'api-secret' plus a
# Deployment 'gateway' whose container references the Secret via a
# secretKeyRef key name (APITOKEN) that does not match the Secret's actual
# key (API_TOKEN), causing CreateContainerConfigError. The Deployment/ReplicaSet
# objects are admitted fine at the API level, but the kubelet fails to start
# the container, so the rollout never reaches 1/1 ready - this script still
# must exit 0.

set -uo pipefail

QUESTION_ID="q105-26-diagnose-crashloop-missing-secret-key${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f - || {
  echo "setup.sh: failed to create/apply namespace $QUESTION_ID" >&2
  exit 1
}
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: api-secret
  labels:
    clusterdrill-question: $QUESTION_ID
stringData:
  API_TOKEN: sample-token-value
EOF

# Deliberately broken: the container's env var references secretKeyRef.key
# "APITOKEN" (missing underscore), but api-secret only has the key
# "API_TOKEN". The Deployment/ReplicaSet/Pod objects are admitted fine, but
# the kubelet fails to start the container with CreateContainerConfigError -
# this is the bug the candidate must diagnose and fix.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gateway
  labels:
    app: gateway
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: gateway
  template:
    metadata:
      labels:
        app: gateway
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: gateway
          image: busybox:1.36
          command: ["sh", "-c", "echo starting; sleep 3600"]
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
          env:
            - name: API_TOKEN
              valueFrom:
                secretKeyRef:
                  name: api-secret
                  key: APITOKEN
EOF

echo "setup.sh: $QUESTION_ID ready"
