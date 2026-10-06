#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q113-10-sticky-canary-session-affinity${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

for v in stable canary; do
  replicas=4
  [ "$v" = "canary" ] && replicas=1
  kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: whoami-$v
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: $replicas
  selector:
    matchLabels:
      svc: whoami
      version: $v
  template:
    metadata:
      labels:
        svc: whoami
        version: $v
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: whoami
          image: busybox:1.36
          command: ["sh", "-c", "mkdir -p /www && hostname > /www/index.html && httpd -f -p 80 -h /www"]
          ports:
            - containerPort: 80
EOF
done

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: whoami
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    svc: whoami
  ports:
    - port: 80
      targetPort: 80
EOF

kubectl wait --for=condition=Available deployment/whoami-stable -n "$QUESTION_ID" --timeout=90s || true
kubectl wait --for=condition=Available deployment/whoami-canary -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
