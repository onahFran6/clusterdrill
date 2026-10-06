#!/usr/bin/env bash
# Idempotent: creates/resets the namespace and makes sure
# /mnt/q114-06-data exists on the node (a `local` PV, unlike hostPath,
# never creates its own directory on demand). Everything else - the
# StorageClass, PV, PVC and Pod - is built by the candidate.
set -euo pipefail

QUESTION_ID="q114-06-storageclass-for-local-disks${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: ${QUESTION_ID}-mkdir
  namespace: $QUESTION_ID
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  restartPolicy: Never
  containers:
    - name: mkdir
      image: busybox:1.36
      command: ["sh", "-c", "mkdir -p /mnt/q114-06-data && chmod 777 /mnt/q114-06-data"]
      volumeMounts:
        - name: hostmnt
          mountPath: /mnt
  volumes:
    - name: hostmnt
      hostPath:
        path: /mnt
EOF

kubectl wait --for=jsonpath='{.status.phase}'=Succeeded "pod/${QUESTION_ID}-mkdir" \
  --namespace="$QUESTION_ID" --timeout=60s
kubectl delete pod "${QUESTION_ID}-mkdir" --namespace="$QUESTION_ID" --ignore-not-found

echo "setup.sh: $QUESTION_ID ready"
