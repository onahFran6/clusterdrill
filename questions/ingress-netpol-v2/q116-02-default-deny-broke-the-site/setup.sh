#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q116-02-default-deny-broke-the-site${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: site
  labels:
    app: site
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: site
  template:
    metadata:
      labels:
        app: site
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: site
          image: hashicorp/http-echo:1.0
          args: ["-listen=:5678", "-text=site"]
          ports:
            - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: site-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: site
  ports:
    - port: 80
      targetPort: 5678
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nova
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  ingressClassName: nginx
  rules:
    - host: nova.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: site-svc
                port:
                  number: 80
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  podSelector: {}
  policyTypes: ["Ingress"]
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

kubectl wait --for=condition=Available deployment/site -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
