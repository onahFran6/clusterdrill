#!/usr/bin/env bash
# Idempotent: creates/resets namespace q108-28-diagnose-dns-wrong-namespace-suffix
# and seeds broken/partial resources.
#
# This question needs TWO extra namespaces (a frontend client and a backend
# it talks to over Service DNS). full_reset (lib/grading.sh) only knows how
# to delete the exact $QUESTION_ID namespace by name and any CLUSTER-SCOPED
# object labeled clusterdrill-question=$QUESTION_ID - it does not delete
# other namespaces, even labeled ones. So - matching the established pattern
# for multi-namespace questions in this bank (see
# q110-30-crd-crossnamespace-count-and-cleanup) - FRONTEND_NS/BACKEND_NS
# below are named as suffixes of $QUESTION_ID, but neither the namespaces
# nor the objects inside them carry the clusterdrill-question label (doing
# so would make verify-question.sh's leak check fail forever, since nothing
# ever deletes them). setup.sh is instead responsible for its own
# idempotency by deleting and recreating both namespaces wholesale on every
# run, which is also this question's actual cleanup path.

set -euo pipefail

QUESTION_ID="q108-28-diagnose-dns-wrong-namespace-suffix${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
FRONTEND_NS="${QUESTION_ID}-frontend"
BACKEND_NS="${QUESTION_ID}-backend"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# The two working namespaces have no framework-level cleanup path (full_reset
# only knows the primary $QUESTION_ID namespace by exact name), so always
# start by removing any leftover copy from a previous run before recreating.
kubectl delete namespace "$FRONTEND_NS" --ignore-not-found --wait=true >/dev/null 2>&1
kubectl delete namespace "$BACKEND_NS" --ignore-not-found --wait=true >/dev/null 2>&1

kubectl create namespace "$FRONTEND_NS" \
  --dry-run=client -o yaml | kubectl apply -f -
apply_default_resource_limits "$FRONTEND_NS"
grant_user_namespace_access "$FRONTEND_NS" "${CLUSTERDRILL_USER_ID:-}"

kubectl create namespace "$BACKEND_NS" \
  --dry-run=client -o yaml | kubectl apply -f -
apply_default_resource_limits "$BACKEND_NS"
grant_user_namespace_access "$BACKEND_NS" "${CLUSTERDRILL_USER_ID:-}"

# --- Backend: orders-api Deployment + orders-svc Service, actually serving. ---
kubectl apply -n "$BACKEND_NS" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: orders-api
  labels:
    app: orders-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: orders-api
  template:
    metadata:
      labels:
        app: orders-api
    spec:
      containers:
        - name: orders-api
          image: hashicorp/http-echo:1.0
          args:
            - "-listen=:8080"
            - "-text=orders-api-ok"
          ports:
            - containerPort: 8080
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
  name: orders-svc
spec:
  selector:
    app: orders-api
  ports:
    - port: 8080
      targetPort: 8080
EOF

kubectl wait --for=condition=Available deployment/orders-api -n "$BACKEND_NS" --timeout=90s || true

# --- Frontend: web-ui Deployment with a hardcoded, WRONG backend namespace
# suffix baked into ORDERS_URL. The container loops curling ORDERS_URL and
# writes "ok" to /tmp/health only on HTTP 200; the liveness probe reads that
# file, so a perpetually-unreachable ORDERS_URL keeps the pod CrashLoopBackOff
# / never-Ready until the candidate fixes the env var.
kubectl apply -n "$FRONTEND_NS" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-ui
  labels:
    app: web-ui
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web-ui
  template:
    metadata:
      labels:
        app: web-ui
    spec:
      containers:
        - name: web-ui
          image: nicolaka/netshoot:latest
          command:
            - sh
            - -c
            - |
              rm -f /tmp/health
              while true; do
                if curl -s -o /dev/null -w '%{http_code}' "\$ORDERS_URL" 2>/dev/null | grep -q '^200\$'; then
                  echo ok > /tmp/health
                else
                  rm -f /tmp/health
                fi
                sleep 2
              done
          env:
            - name: ORDERS_URL
              value: "http://orders-svc.${QUESTION_ID}-backend-old.svc.cluster.local:8080/"
          readinessProbe:
            exec:
              command: ["cat", "/tmp/health"]
            initialDelaySeconds: 2
            periodSeconds: 3
            failureThreshold: 3
          livenessProbe:
            exec:
              command: ["cat", "/tmp/health"]
            initialDelaySeconds: 10
            periodSeconds: 5
            failureThreshold: 6
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
EOF

kubectl wait --for=condition=Available deployment/web-ui -n "$FRONTEND_NS" --timeout=30s || true

echo "setup.sh: $QUESTION_ID ready (web-ui in $FRONTEND_NS has a broken ORDERS_URL pointing at nonexistent namespace ${QUESTION_ID}-backend-old; real backend is orders-svc in $BACKEND_NS)"
