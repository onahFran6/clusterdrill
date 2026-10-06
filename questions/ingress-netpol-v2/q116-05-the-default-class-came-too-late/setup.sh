#!/usr/bin/env bash
# IngressClass is cluster-scoped, so this question's own class is named
# uniquely per question (q116-05-ingress-class, never a bare "nginx") to
# avoid colliding with - or mutating the default-class annotation on - a
# real "nginx" IngressClass that may genuinely already exist on whatever
# cluster this bank is pointed at (e.g. minikube's own "ingress" addon
# installs one, already marked default). It carries the
# clusterdrill-question label so full_reset's cluster-scoped cleanup (which
# includes ingressclass) removes it.
set -euo pipefail

QUESTION_ID="q116-05-the-default-class-came-too-late${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# Our own IngressClass, deliberately NOT annotated default yet - that is
# the candidate's job. Delete-then-create (not apply) so a re-run always
# starts from a clean, non-default IngressClass even if a previous run's
# candidate already annotated it.
kubectl delete ingressclass q116-05-ingress-class --ignore-not-found >/dev/null 2>&1
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: q116-05-ingress-class
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  controller: k8s.io/ingress-nginx
EOF

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  labels:
    app: web
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: web
          image: hashicorp/http-echo:1.0
          args: ["-listen=:5678", "-text=web"]
          ports:
            - containerPort: 5678
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
      targetPort: 5678
EOF

# Classless Ingress: no spec.ingressClassName set here. On a cluster that
# already has some other IngressClass marked default (e.g. "nginx"), the
# DefaultIngressClass admission step bakes that class in immediately, at
# this creation - this is the exact starting state the Task is about
# (whichever class resolved here, or none, if the cluster has no default
# at all yet).
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: pulsar
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  rules:
    - host: pulsar.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web-svc
                port:
                  number: 80
EOF

kubectl wait --for=condition=Available deployment/web -n "$QUESTION_ID" --timeout=90s || true

echo "setup.sh: $QUESTION_ID ready"
