#!/usr/bin/env bash
# Idempotent: creates/resets namespace q102-25-ambassador-wrong-port-two-services
# and seeds two backend Deployments/Services ("catalog-primary" returning
# "PRIMARY", "catalog-standby" returning "STANDBY") plus a BROKEN
# "catalog-gateway" Pod: the "proxy" ambassador container's socat command
# forwards localhost:9090 to catalog-standby:8080 instead of
# catalog-primary:8080. The "client" container only ever talks to
# localhost:9090, so from its point of view nothing looks wrong until you
# actually curl it and see STANDBY's body instead of PRIMARY's.
set -euo pipefail

QUESTION_ID="q102-25-ambassador-wrong-port-two-services${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# --- Backend 1: catalog-primary, responds with body "PRIMARY" -------------
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: catalog-primary
  labels:
    clusterdrill-question: $QUESTION_ID
    app: catalog-primary
spec:
  replicas: 1
  selector:
    matchLabels:
      app: catalog-primary
  template:
    metadata:
      labels:
        app: catalog-primary
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: web
          image: nginx:1.25-alpine
          command: ["sh", "-c", "echo -n PRIMARY > /usr/share/nginx/html/index.html && nginx -g 'daemon off;'"]
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
---
apiVersion: v1
kind: Service
metadata:
  name: catalog-primary
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: catalog-primary
  ports:
    - port: 8080
      targetPort: 80
EOF

# --- Backend 2: catalog-standby, responds with body "STANDBY" -------------
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: catalog-standby
  labels:
    clusterdrill-question: $QUESTION_ID
    app: catalog-standby
spec:
  replicas: 1
  selector:
    matchLabels:
      app: catalog-standby
  template:
    metadata:
      labels:
        app: catalog-standby
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: web
          image: nginx:1.25-alpine
          command: ["sh", "-c", "echo -n STANDBY > /usr/share/nginx/html/index.html && nginx -g 'daemon off;'"]
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
---
apiVersion: v1
kind: Service
metadata:
  name: catalog-standby
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: catalog-standby
  ports:
    - port: 8080
      targetPort: 80
EOF

# --- The broken ambassador Pod --------------------------------------------
# "proxy" forwards localhost:9090 to catalog-standby:8080 (wrong backend).
# The candidate must recreate this Pod so "proxy" forwards to
# catalog-primary:8080 instead.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: catalog-gateway
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: client
      image: busybox:1.36
      command: ["sh", "-c", "while true; do wget -q -T 2 -O - http://localhost:9090 || true; sleep 5; done"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
    - name: proxy
      image: alpine:3.20
      command: ["sh", "-c", "apk add --no-cache socat && socat TCP-LISTEN:9090,fork,reuseaddr TCP:catalog-standby:8080"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
EOF

echo "setup.sh: $QUESTION_ID ready"
