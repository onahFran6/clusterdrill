#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q109-16-volume-subpath-single-file${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: shared-storage
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 200Mi
EOF

kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/shared-storage -n "$QUESTION_ID" --timeout=60s

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: seed-writer
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  restartPolicy: Never
  containers:
    - name: seed-writer
      image: busybox:1.36
      command: ["sh", "-c", "echo -n 'ready=true' > /mnt/full/app.conf"]
      volumeMounts:
        - name: storage
          mountPath: /mnt/full
  volumes:
    - name: storage
      persistentVolumeClaim:
        claimName: shared-storage
EOF

kubectl wait --for=condition=Ready=false pod/seed-writer -n "$QUESTION_ID" --timeout=90s 2>/dev/null || true

# Wait for the helper pod to reach a terminal Succeeded phase before this
# script returns, so the candidate never sees a race on app.conf's contents.
for i in $(seq 1 60); do
  phase="$(kubectl get pod seed-writer -n "$QUESTION_ID" -o jsonpath='{.status.phase}' 2>/dev/null || true)"
  if [[ "$phase" == "Succeeded" ]]; then
    break
  fi
  if [[ "$phase" == "Failed" ]]; then
    echo "setup.sh: seed-writer pod failed" >&2
    kubectl logs seed-writer -n "$QUESTION_ID" >&2 || true
    exit 1
  fi
  sleep 2
done

kubectl delete pod seed-writer -n "$QUESTION_ID" --ignore-not-found --wait=true >/dev/null 2>&1

echo "setup.sh: $QUESTION_ID ready"
