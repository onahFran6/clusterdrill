#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q109-26-pv-released-manual-rebind${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

mkdir -p /tmp/ckad-legacy-pv

kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: legacy-pv
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  capacity:
    storage: 80Mi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ""
  hostPath:
    path: /tmp/ckad-legacy-pv
EOF

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: legacy-claim
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ""
  resources:
    requests:
      storage: 80Mi
  volumeName: legacy-pv
EOF

kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/legacy-claim -n "$QUESTION_ID" --timeout=60s

kubectl delete pvc legacy-claim -n "$QUESTION_ID" --wait=true

# Wait for the PV to settle into Released phase now that its claim is gone.
for i in $(seq 1 30); do
  phase="$(kubectl get pv legacy-pv -o jsonpath='{.status.phase}' 2>/dev/null || true)"
  if [[ "$phase" == "Released" ]]; then
    break
  fi
  sleep 1
done

echo "setup.sh: $QUESTION_ID ready"
