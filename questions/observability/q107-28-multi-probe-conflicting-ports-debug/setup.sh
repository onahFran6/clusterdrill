#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q107-28-multi-probe-conflicting-ports-debug${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: nginx-conf
  labels:
    app: payments-gw
    clusterdrill-question: $QUESTION_ID
data:
  default.conf: |
    server {
        listen 8081;
        server_name localhost;

        location / {
            root   /usr/share/nginx/html;
            index  index.html index.htm;
        }
    }
---
apiVersion: v1
kind: Pod
metadata:
  name: payments-gw
  labels:
    app: payments-gw
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: payments-gw
      image: nginx:1.25-alpine
      ports:
        - containerPort: 8081
      volumeMounts:
        - name: nginx-conf
          mountPath: /etc/nginx/conf.d/default.conf
          subPath: default.conf
      startupProbe:
        httpGet:
          path: /
          port: 80
        periodSeconds: 2
        failureThreshold: 5
      livenessProbe:
        httpGet:
          path: /
          port: 80
        periodSeconds: 5
        failureThreshold: 3
      readinessProbe:
        httpGet:
          path: /
          port: 80
        periodSeconds: 5
        failureThreshold: 3
  volumes:
    - name: nginx-conf
      configMap:
        name: nginx-conf
EOF

# This pod is expected to be broken (stuck starting) right after setup -
# that's the point of the question - so don't block setup.sh on readiness.
kubectl wait --for=condition=Ready pod/payments-gw -n "$QUESTION_ID" --timeout=20s || true

echo "setup.sh: $QUESTION_ID ready"
