#!/usr/bin/env bash
# Idempotent: creates/resets namespace q105-24-secret-from-literal-multiple-keys
# and seeds a pod that references a Secret (db-creds) which does not exist
# yet, so it sits in ContainerCreating until the candidate creates it. Every
# cluster object created here carries the label
# clusterdrill-question=q105-24-secret-from-literal-multiple-keys
#.

set -euo pipefail

QUESTION_ID="q105-24-secret-from-literal-multiple-keys${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# db-creds is deliberately NOT created here - the pod below references it
# via subPath and will sit in ContainerCreating until the candidate creates
# the Secret with both required keys.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: dbclient
  labels:
    app: dbclient
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: dbclient
      image: nginx:1.25-alpine
      volumeMounts:
        - name: db-creds
          mountPath: /etc/db/password
          subPath: password
          readOnly: true
  volumes:
    - name: db-creds
      secret:
        secretName: db-creds
EOF

echo "setup.sh: $QUESTION_ID ready"
