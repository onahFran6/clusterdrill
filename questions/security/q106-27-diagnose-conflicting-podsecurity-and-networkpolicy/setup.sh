#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds a namespace-wide 'restricted'
# PodSecurity label, a default-deny NetworkPolicy, a Service expecting a pod
# labeled app=worker, and attempts to apply a privileged Pod named 'worker'
# that the restricted PodSecurity admission controller rejects outright - so
# the Pod never actually gets created. That apply is allowed to fail; this
# script still must exit 0.

set -uo pipefail

QUESTION_ID="q106-27-diagnose-conflicting-podsecurity-and-networkpolicy${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f - || {
  echo "setup.sh: failed to create/apply namespace $QUESTION_ID" >&2
  exit 1
}
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
# The conflicting constraint the candidate must diagnose: this namespace
# enforces the 'restricted' Pod Security Standard.
kubectl label namespace "$QUESTION_ID" "pod-security.kubernetes.io/enforce=restricted" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# Legitimate supporting resources: default-deny NetworkPolicy + a Service
# that already expects a pod labeled app=worker on port 80.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  podSelector: {}
  policyTypes:
    - Ingress
---
apiVersion: v1
kind: Service
metadata:
  name: worker-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: worker
  ports:
    - port: 8080
      targetPort: 8080
EOF

# Deliberately broken: this Pod requests privileged:true, which the
# 'restricted' PodSecurity label on this namespace forbids. The API server's
# admission controller rejects the request outright, so 'worker' never gets
# created. This apply is EXPECTED to fail - do not let that abort setup.sh.
kubectl apply -n "$QUESTION_ID" -f - <<EOF || echo "setup.sh: expected admission rejection of privileged 'worker' pod (this is the bug the candidate must diagnose)"
apiVersion: v1
kind: Pod
metadata:
  name: worker
  labels:
    app: worker
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: worker
      image: nginx:1.25-alpine
      ports:
        - containerPort: 8080
      securityContext:
        privileged: true
EOF

echo "setup.sh: $QUESTION_ID ready"
