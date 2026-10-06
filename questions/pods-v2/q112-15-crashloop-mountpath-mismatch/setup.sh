#!/usr/bin/env bash
# Idempotent: creates/resets the namespace and seeds a ConfigMap plus a
# broken Pod whose volume mountPath (/conf) doesn't match the path its
# command actually reads (/config) - that mismatch is the whole fault.
set -euo pipefail

QUESTION_ID="q112-15-crashloop-mountpath-mismatch${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: app-conf
  labels:
    clusterdrill-question: $QUESTION_ID
data:
  app.conf: mode=fast
---
apiVersion: v1
kind: Pod
metadata:
  name: calc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  volumes:
    - name: conf
      configMap:
        name: app-conf
  containers:
    - name: calc
      image: busybox:1.36
      command: ["sh", "-c", "cat /config/app.conf && sleep 3600"]
      volumeMounts:
        - name: conf
          mountPath: /conf
EOF

echo "setup.sh: $QUESTION_ID ready"
