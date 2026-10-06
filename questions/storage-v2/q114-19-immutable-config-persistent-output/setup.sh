#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q114-19-immutable-config-persistent-output${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
kind: ConfigMap
metadata:
  name: render-v1
  labels:
    clusterdrill-question: $QUESTION_ID
immutable: true
data:
  greeting: hello
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: render-out
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 100Mi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: render
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: render
  template:
    metadata:
      labels:
        app: render
        clusterdrill-question: $QUESTION_ID
    spec:
      volumes:
        - name: tpl
          configMap:
            name: render-v1
        - name: out
          persistentVolumeClaim:
            claimName: render-out
      containers:
        - name: render
          image: busybox:1.36
          command: ["sh", "-c", "echo \"\$(cat /tpl/greeting) world \$(date +%T)\" >> /out/history; sleep 3600"]
          volumeMounts:
            - name: tpl
              mountPath: /tpl
            - name: out
              mountPath: /out
EOF

kubectl rollout status deployment/render -n "$QUESTION_ID" --timeout=60s

echo "setup.sh: $QUESTION_ID ready"
