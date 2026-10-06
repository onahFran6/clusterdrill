#!/usr/bin/env bash
# This question needs a second namespace (another team's - its
# NetworkPolicy must never be edited by the candidate). Per the
# established pattern for multi-namespace questions in this bank (see
# q108-28-diagnose-dns-wrong-namespace-suffix), DATA_NS below is named as
# a suffix of $QUESTION_ID, carries no clusterdrill-question label (neither
# do the objects inside it), and is deleted/recreated wholesale on every
# run for its own idempotency.
set -euo pipefail

QUESTION_ID="q116-20-end-to-end-four-faults-one-request${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
DATA_NS="${QUESTION_ID}-data"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
# Deliberately NOT labeled team=carina yet - that is fault #4's cause.
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl delete namespace "$DATA_NS" --ignore-not-found --wait=true >/dev/null 2>&1
kubectl create namespace "$DATA_NS" \
  --dry-run=client -o yaml | kubectl apply -f -
apply_default_resource_limits "$DATA_NS"
grant_user_namespace_access "$DATA_NS" "${CLUSTERDRILL_USER_ID:-}"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: web
  labels:
    app: web
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: web
      image: busybox:1.36
      command: ["sh", "-c", "mkdir -p /www && echo web ok > /www/index.html && httpd -f -p 8080 -h /www"]
---
apiVersion: v1
kind: Service
metadata:
  name: web-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 8080
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  podSelector: {}
  policyTypes: ["Ingress", "Egress"]
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: web-to-quotes
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes: ["Egress"]
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: $DATA_NS
          podSelector:
            matchLabels:
              app: quotes
      ports:
        - protocol: TCP
          port: 80
EOF

# Fault #1: the Ingress backend is wrongly pointed at the container's own
# port (8080) instead of the Service's real port (80).
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: carina
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  ingressClassName: nginx
  rules:
    - host: carina.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web-svc
                port:
                  number: 8080
EOF

# The other team's namespace and its own NetworkPolicy, requiring the
# caller's namespace to carry label team=carina (fault #4's cause) - never
# edited by the candidate.
kubectl apply -n "$DATA_NS" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: quotes
  labels:
    app: quotes
spec:
  containers:
    - name: quotes
      image: busybox:1.36
      command: ["sh", "-c", "mkdir -p /www && echo quotes ok > /www/index.html && httpd -f -p 80 -h /www"]
---
apiVersion: v1
kind: Service
metadata:
  name: quotes-svc
spec:
  selector:
    app: quotes
  ports:
    - port: 80
      targetPort: 80
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: quotes-from-carina
spec:
  podSelector:
    matchLabels:
      app: quotes
  policyTypes: ["Ingress"]
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              team: carina
EOF

kubectl wait --for=condition=Ready pod/web -n "$QUESTION_ID" --timeout=60s || true
kubectl wait --for=condition=Ready pod/quotes -n "$DATA_NS" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready (second namespace: $DATA_NS)"
