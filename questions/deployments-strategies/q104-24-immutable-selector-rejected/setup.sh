#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q104-24-immutable-selector-rejected${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: notify-service
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 2
  selector:
    matchLabels:
      app: notify-service
  template:
    metadata:
      labels:
        app: notify-service
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: notify-service
          image: busybox:1.36
          command: ["sleep", "3600"]
EOF

kubectl rollout status deployment/notify-service -n "$QUESTION_ID" --timeout=60s || true

# Reference-only context for the candidate: a copy of the patch someone
# tried that the API server rejected for touching the immutable selector.
# Not graded by check.sh.
WORK_DIR="$(question_workdir "$QUESTION_ID")"
cat > "$WORK_DIR/attempted-selector-patch.yaml" <<'EOF'
# REJECTED by the API server - spec.selector is immutable once a
# Deployment exists:
#   error: Deployment.apps "notify-service" is invalid:
#   spec.selector: Invalid value: ...: field is immutable
apiVersion: apps/v1
kind: Deployment
metadata:
  name: notify-service
spec:
  selector:
    matchLabels:
      app: notify-service-v2
  template:
    metadata:
      labels:
        app: notify-service-v2
EOF

echo "setup.sh: $QUESTION_ID ready"
