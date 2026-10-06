#!/usr/bin/env bash
# Idempotent: creates/resets the namespace and seeds a correct Secret plus
# a Pod with three independent, stacked faults: a PVC that doesn't exist
# yet, a nonexistent image tag, and a secretKeyRef typo.
set -euo pipefail

QUESTION_ID="q112-16-three-faults-three-stages${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: report-secret
  labels:
    clusterdrill-question: $QUESTION_ID
stringData:
  api-key: xyz789
---
apiVersion: v1
kind: Pod
metadata:
  name: report
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: report-data
  containers:
    - name: report
      image: busybox:1.366
      command: ["sleep", "3600"]
      env:
        - name: API_KEY
          valueFrom:
            secretKeyRef:
              name: report-secret
              key: apikey
      volumeMounts:
        - name: data
          mountPath: /data
EOF

echo "setup.sh: $QUESTION_ID ready"
