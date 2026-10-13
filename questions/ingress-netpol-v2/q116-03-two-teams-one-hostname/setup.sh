#!/usr/bin/env bash
# This question needs a second namespace (team Blog's own namespace).
# BLOG_NS below is named as a suffix of $QUESTION_ID and labeled
# clusterdrill-question=$QUESTION_ID, same as the primary namespace (R06):
# full_reset/batch_cleanup select namespaces to delete by this label, not
# by $QUESTION_ID's exact name, so this secondary namespace is swept up and
# cleaned at session end exactly like the primary one, instead of leaking
# forever. setup.sh is still responsible for its own idempotency on
# repeated runs of this one question: deleting and recreating BLOG_NS
# wholesale on every run.
set -euo pipefail

QUESTION_ID="q116-03-two-teams-one-hostname${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
BLOG_NS="${QUESTION_ID}-blog"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl delete namespace "$BLOG_NS" --ignore-not-found --wait=true >/dev/null 2>&1
kubectl create namespace "$BLOG_NS" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$BLOG_NS" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$BLOG_NS"
grant_user_namespace_access "$BLOG_NS" "${CLUSTERDRILL_USER_ID:-}"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop
  labels:
    app: shop
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: shop
  template:
    metadata:
      labels:
        app: shop
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: shop
          image: hashicorp/http-echo:1.0
          args: ["-listen=:5678", "-text=shop"]
          ports:
            - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: shop-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: shop
  ports:
    - port: 80
      targetPort: 5678
EOF

kubectl apply -n "$BLOG_NS" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: blog
  labels:
    app: blog
spec:
  replicas: 1
  selector:
    matchLabels:
      app: blog
  template:
    metadata:
      labels:
        app: blog
    spec:
      containers:
        - name: blog
          image: hashicorp/http-echo:1.0
          args: ["-listen=:5678", "-text=blog"]
          ports:
            - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: blog-svc
spec:
  selector:
    app: blog
  ports:
    - port: 80
      targetPort: 5678
EOF

kubectl wait --for=condition=Available deployment/shop -n "$QUESTION_ID" --timeout=90s || true
kubectl wait --for=condition=Available deployment/blog -n "$BLOG_NS" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready (second namespace: $BLOG_NS)"
