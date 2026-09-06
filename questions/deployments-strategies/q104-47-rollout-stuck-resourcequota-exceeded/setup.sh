#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q104-47-rollout-stuck-resourcequota-exceeded${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: checkout-worker
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: checkout-worker
  template:
    metadata:
      labels:
        app: checkout-worker
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: checkout-worker
          image: busybox:1.35
          command: ["sleep", "3600"]
          resources:
            requests:
              cpu: 300m
            limits:
              cpu: 300m
EOF

kubectl rollout status deployment/checkout-worker -n "$QUESTION_ID" --timeout=60s || true

# Now trigger the broken rollout: image update + a CPU bump that, combined
# with the still-running old pod, exceeds the namespace's requests.cpu quota
# (600m). The new pod's creation is rejected by admission, so this never
# progresses on its own.
kubectl set image deployment/checkout-worker checkout-worker=busybox:1.36 -n "$QUESTION_ID"
kubectl set resources deployment/checkout-worker -c checkout-worker \
  --requests=cpu=550m --limits=cpu=550m -n "$QUESTION_ID"
sleep 5

echo "setup.sh: $QUESTION_ID ready (checkout-worker rollout stuck on ResourceQuota)"
