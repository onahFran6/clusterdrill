#!/usr/bin/env bash
# Requires metrics-server already installed in the cluster. Creates two
# idle pods and one CPU-burning pod, then waits long enough for
# metrics-server to have collected at least one sample before finishing.
set -euo pipefail

QUESTION_ID="q107-18-top-pod-identify-hungry-container${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
kind: Pod
metadata:
  name: quiet-a
  labels:
    app: quiet-a
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: quiet-a
      image: busybox:1.36
      command: ["sleep", "3600"]
---
apiVersion: v1
kind: Pod
metadata:
  name: quiet-b
  labels:
    app: quiet-b
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: quiet-b
      image: busybox:1.36
      command: ["sleep", "3600"]
---
apiVersion: v1
kind: Pod
metadata:
  name: burner
  labels:
    app: burner
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: burner
      image: busybox:1.36
      command: ["sh", "-c", "while true; do :; done"]
      resources:
        requests:
          cpu: "200m"
          memory: "64Mi"
        limits:
          cpu: "500m"
          memory: "128Mi"
EOF

kubectl wait --for=condition=Ready pod/quiet-a -n "$QUESTION_ID" --timeout=120s
kubectl wait --for=condition=Ready pod/quiet-b -n "$QUESTION_ID" --timeout=120s
kubectl wait --for=condition=Ready pod/burner -n "$QUESTION_ID" --timeout=120s

# Give metrics-server time to scrape and aggregate at least one CPU sample
# for all three pods (its default resolution is ~60s) before the candidate
# starts, so `kubectl top pod` returns real, distinguishing numbers.
echo "setup.sh: $QUESTION_ID waiting 75s for metrics-server to collect a sample..."
sleep 75

echo "setup.sh: $QUESTION_ID ready"
