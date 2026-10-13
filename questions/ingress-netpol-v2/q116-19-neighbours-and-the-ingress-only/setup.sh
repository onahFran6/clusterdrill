#!/usr/bin/env bash
# This question needs a second namespace (an unrelated "stranger" pod's
# home). STRANGER_NS below is named as a suffix of $QUESTION_ID and
# labeled clusterdrill-question=$QUESTION_ID, same as the primary namespace
# (R06): full_reset/batch_cleanup select namespaces to delete by this
# label, so STRANGER_NS is swept up and cleaned at session end exactly like
# the primary one. It's also still deleted/recreated wholesale on every
# run for its own idempotency on repeated runs of this one question.
set -euo pipefail

QUESTION_ID="q116-19-neighbours-and-the-ingress-only${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
STRANGER_NS="${QUESTION_ID}-stranger"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl delete namespace "$STRANGER_NS" --ignore-not-found --wait=true >/dev/null 2>&1
kubectl create namespace "$STRANGER_NS" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$STRANGER_NS" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$STRANGER_NS"
grant_user_namespace_access "$STRANGER_NS" "${CLUSTERDRILL_USER_ID:-}"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: shop
  labels:
    app: shop
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: shop
      image: hashicorp/http-echo:1.0
      args: ["-listen=:5678", "-text=shop"]
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
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: fornax
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  ingressClassName: nginx
  rules:
    - host: fornax.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: shop-svc
                port:
                  number: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: neighbour
  labels:
    app: neighbour
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: neighbour
      image: busybox:1.36
      command: ["sleep", "3600"]
EOF

kubectl apply -n "$STRANGER_NS" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: stranger
spec:
  containers:
    - name: stranger
      image: busybox:1.36
      command: ["sleep", "3600"]
EOF

kubectl wait --for=condition=Ready pod/shop -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready (second namespace: $STRANGER_NS)"
