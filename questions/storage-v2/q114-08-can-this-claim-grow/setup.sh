#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q114-08-can-this-claim-grow${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
kind: PersistentVolumeClaim
metadata:
  name: tiber-data
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 200Mi
EOF

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: holder
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  volumes:
    - name: d
      persistentVolumeClaim:
        claimName: tiber-data
  containers:
    - name: h
      image: busybox:1.36
      command: ["sleep", "3600"]
      volumeMounts:
        - name: d
          mountPath: /data
EOF

kubectl wait --for=condition=Ready pod/holder -n "$QUESTION_ID" --timeout=60s

echo "setup.sh: $QUESTION_ID ready"
