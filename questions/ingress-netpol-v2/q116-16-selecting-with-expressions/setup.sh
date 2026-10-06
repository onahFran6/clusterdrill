#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q116-16-selecting-with-expressions${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: ledger
  labels:
    app: ledger
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: ledger
      image: hashicorp/http-echo:1.0
      args: ["-listen=:5678", "-text=ledger"]
---
apiVersion: v1
kind: Service
metadata:
  name: ledger-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: ledger
  ports:
    - port: 80
      targetPort: 5678
---
apiVersion: v1
kind: Pod
metadata:
  name: p1
  labels:
    team: payments
    env: prod
    audited: "yes"
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: p1
      image: busybox:1.36
      command: ["sleep", "3600"]
---
apiVersion: v1
kind: Pod
metadata:
  name: p2
  labels:
    team: billing
    env: dev
    audited: "yes"
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: p2
      image: busybox:1.36
      command: ["sleep", "3600"]
---
apiVersion: v1
kind: Pod
metadata:
  name: p3
  labels:
    team: billing
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: p3
      image: busybox:1.36
      command: ["sleep", "3600"]
---
apiVersion: v1
kind: Pod
metadata:
  name: p4
  labels:
    team: billing
    audited: "no"
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: p4
      image: busybox:1.36
      command: ["sleep", "3600"]
EOF

kubectl wait --for=condition=Ready pod/ledger -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
