#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q114-16-deleted-while-in-use${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# Idempotent: only run the delete-while-in-use dance if the claim isn't
# already Terminating from a prior standalone run.
deletion_ts="$(kubectl get pvc data -n "$QUESTION_ID" -o jsonpath='{.metadata.deletionTimestamp}' 2>/dev/null || true)"
if [[ -z "$deletion_ts" ]]; then
  kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 100Mi
EOF

  kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/data -n "$QUESTION_ID" --timeout=60s

  # The dynamically-provisioned PV's name is unpredictable and the PVC is
  # about to be deleted - label it now, immediately after binding, so
  # check.sh can still find it later.
  pv_name="$(kubectl get pvc data -n "$QUESTION_ID" -o jsonpath='{.spec.volumeName}')"
  kubectl label pv "$pv_name" "clusterdrill-question=$QUESTION_ID" --overwrite

  kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: app
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  volumes:
    - name: d
      persistentVolumeClaim:
        claimName: data
  containers:
    - name: a
      image: busybox:1.36
      command: ["sh", "-c", "echo keep me > /data/msg; sleep 3600"]
      volumeMounts:
        - name: d
          mountPath: /data
EOF

  kubectl wait --for=condition=Ready pod/app -n "$QUESTION_ID" --timeout=60s
  kubectl delete pvc data -n "$QUESTION_ID" --wait=false
fi

echo "setup.sh: $QUESTION_ID ready"
