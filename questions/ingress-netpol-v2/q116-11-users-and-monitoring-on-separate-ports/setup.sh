#!/usr/bin/env bash
# This question needs a second namespace (the monitoring team's own). Per
# the established pattern for multi-namespace questions in this bank (see
# q108-28-diagnose-dns-wrong-namespace-suffix), MONITORING_NS below is
# named as a suffix of $QUESTION_ID, but neither the namespace nor the pod
# inside it carries the clusterdrill-question label (full_reset never
# sweeps other namespaces). setup.sh is instead responsible for its own
# idempotency by deleting and recreating MONITORING_NS wholesale on every
# run.
set -euo pipefail

QUESTION_ID="q116-11-users-and-monitoring-on-separate-ports${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
MONITORING_NS="${QUESTION_ID}-monitoring"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl delete namespace "$MONITORING_NS" --ignore-not-found --wait=true >/dev/null 2>&1
kubectl create namespace "$MONITORING_NS" \
  --dry-run=client -o yaml | kubectl apply -f -
apply_default_resource_limits "$MONITORING_NS"
grant_user_namespace_access "$MONITORING_NS" "${CLUSTERDRILL_USER_ID:-}"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  labels:
    app: api
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: api
          image: hashicorp/http-echo:1.0
          args: ["-listen=:5678", "-text=api"]
          ports:
            - name: http
              containerPort: 5678
        - name: metrics
          image: busybox:1.36
          command: ["sh", "-c", "mkdir -p /www && echo up > /www/index.html && httpd -f -p 9100 -h /www"]
          ports:
            - name: metrics
              containerPort: 9100
---
apiVersion: v1
kind: Service
metadata:
  name: api-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: api
  ports:
    - name: http
      port: 80
      targetPort: http
    - name: metrics
      port: 9100
      targetPort: metrics
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: andromeda
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  ingressClassName: nginx
  rules:
    - host: andromeda.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: api-svc
                port:
                  number: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: peer
  labels:
    app: peer
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: peer
      image: busybox:1.36
      command: ["sleep", "3600"]
EOF

kubectl apply -n "$MONITORING_NS" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: prom
spec:
  containers:
    - name: prom
      image: busybox:1.36
      command: ["sleep", "3600"]
EOF

kubectl wait --for=condition=Available deployment/api -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready (second namespace: $MONITORING_NS)"
