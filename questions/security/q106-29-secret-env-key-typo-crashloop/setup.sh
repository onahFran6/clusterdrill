#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds a Secret 'db-creds' plus a
# Pod 'billing-worker' whose container references a nonexistent Secret key
# (passwd instead of password) via secretKeyRef, causing
# CreateContainerConfigError. That apply of the broken Pod is expected to
# succeed at the API level (the object is admitted fine) but the kubelet
# will fail to start the container - this script still must exit 0.

set -uo pipefail

QUESTION_ID="q106-29-secret-env-key-typo-crashloop${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: db-creds
  labels:
    clusterdrill-question: $QUESTION_ID
stringData:
  username: billing-app
  password: s3cr3t-db-pass
EOF

# Deliberately broken: DB_PASS references key 'passwd', which does not exist
# in db-creds (the real key is 'password'). The Pod object itself is
# admitted fine, but the kubelet fails to start the container with
# CreateContainerConfigError - this is the bug the candidate must diagnose.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: billing-worker
  labels:
    app: billing-worker
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: billing-worker
      image: busybox:1.36
      command: ["sh", "-c", "echo starting; sleep 3600"]
      env:
        - name: DB_PASS
          valueFrom:
            secretKeyRef:
              name: db-creds
              key: passwd
EOF

echo "setup.sh: $QUESTION_ID ready"
