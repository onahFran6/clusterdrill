#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q114-10-rollout-stuck-on-its-own-volume${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
kind: PersistentVolume
metadata:
  name: q114-10-pv
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  capacity:
    storage: 1Gi
  accessModes: ["ReadWriteOncePod"]
  storageClassName: manual-q114-10
  hostPath:
    path: /mnt/q114-10-pv
    type: DirectoryOrCreate
EOF

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ledger-db
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  storageClassName: manual-q114-10
  volumeName: q114-10-pv
  accessModes: ["ReadWriteOncePod"]
  resources:
    requests:
      storage: 1Gi
EOF

# Idempotent: only run the broken-upgrade dance (first rollout, then an
# image bump that collides with itself on the RWOP claim) if the
# Deployment doesn't already exist with its broken 1.37 image pending.
current_image="$(kubectl get deployment ledger -n "$QUESTION_ID" \
  -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || true)"
if [[ "$current_image" != "busybox:1.37" ]]; then
  kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ledger
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ledger
  template:
    metadata:
      labels:
        app: ledger
        clusterdrill-question: $QUESTION_ID
    spec:
      volumes:
        - name: db
          persistentVolumeClaim:
            claimName: ledger-db
      containers:
        - name: ledger
          image: busybox:1.36
          command: ["sleep", "3600"]
          volumeMounts:
            - name: db
              mountPath: /db
EOF

  kubectl rollout status deployment/ledger -n "$QUESTION_ID" --timeout=60s
  kubectl set image deployment/ledger ledger=busybox:1.37 -n "$QUESTION_ID"
fi

echo "setup.sh: $QUESTION_ID ready"
