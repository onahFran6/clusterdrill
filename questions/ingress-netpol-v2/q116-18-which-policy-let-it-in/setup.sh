#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q116-18-which-policy-let-it-in${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: db
  labels:
    app: db
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: db
      image: hashicorp/http-echo:1.0
      args: ["-listen=:5678", "-text=db"]
---
apiVersion: v1
kind: Service
metadata:
  name: db-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: db
  ports:
    - port: 80
      targetPort: 5678
---
apiVersion: v1
kind: Pod
metadata:
  name: api
  labels:
    app: api
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: api
      image: busybox:1.36
      command: ["sleep", "3600"]
---
apiVersion: v1
kind: Pod
metadata:
  name: intruder
  labels:
    app: intruder
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: intruder
      image: busybox:1.36
      command: ["sleep", "3600"]
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  podSelector: {}
  policyTypes: ["Ingress"]
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-from-api
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  podSelector:
    matchLabels:
      app: db
  policyTypes: ["Ingress"]
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: api
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-debug
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  podSelector:
    matchLabels:
      app: db
  policyTypes: ["Ingress"]
  ingress:
    - {}
EOF

kubectl wait --for=condition=Ready pod/db -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
