#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q116-15-three-tiers-locked-both-ways${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
kind: Pod
metadata:
  name: web
  labels:
    tier: web
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: web
      image: busybox:1.36
      command: ["sh", "-c", "mkdir -p /www && echo web > /www/index.html && httpd -f -p 8080 -h /www"]
---
apiVersion: v1
kind: Service
metadata:
  name: web-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    tier: web
  ports:
    - port: 80
      targetPort: 8080
---
apiVersion: v1
kind: Pod
metadata:
  name: api
  labels:
    tier: api
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: api
      image: busybox:1.36
      command: ["sh", "-c", "mkdir -p /www && echo api > /www/index.html && httpd -f -p 8080 -h /www"]
---
apiVersion: v1
kind: Service
metadata:
  name: api-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    tier: api
  ports:
    - port: 80
      targetPort: 8080
---
apiVersion: v1
kind: Pod
metadata:
  name: db
  labels:
    tier: db
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: db
      image: busybox:1.36
      command: ["sh", "-c", "while true; do nc -l -p 5432; done"]
---
apiVersion: v1
kind: Service
metadata:
  name: db-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    tier: db
  ports:
    - port: 5432
      targetPort: 5432
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: cartwheel
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  ingressClassName: nginx
  rules:
    - host: cartwheel.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web-svc
                port:
                  number: 80
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
  name: allow-dns
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  podSelector: {}
  policyTypes: ["Egress"]
  egress:
    - ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
EOF

kubectl wait --for=condition=Ready pod/web -n "$QUESTION_ID" --timeout=60s || true
kubectl wait --for=condition=Ready pod/api -n "$QUESTION_ID" --timeout=60s || true
kubectl wait --for=condition=Ready pod/db -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
