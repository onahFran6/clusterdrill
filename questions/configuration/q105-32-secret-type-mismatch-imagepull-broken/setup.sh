#!/usr/bin/env bash
# Idempotent: creates/resets namespace
# q105-32-secret-type-mismatch-imagepull-broken and seeds a Secret
# 'registry-cred' mistakenly created as generic Opaque (a raw
# dockerconfigjson-shaped string stuffed under an arbitrary key 'creds'
# instead of the proper kubernetes.io/dockerconfigjson type/key), plus a
# Deployment 'private-app' whose pod template references registry-cred via
# imagePullSecrets. In a real private registry this malformed secret shape
# is what leaves the kubelet unable to authenticate the pull (kubelet only
# reads '.dockerconfigjson' off a kubernetes.io/dockerconfigjson secret, it
# never scans arbitrary Opaque keys) - the candidate must diagnose that from
# the Secret's type/key shape rather than assume the credentials themselves
# are wrong. This script still must exit 0.

set -uo pipefail

QUESTION_ID="q105-32-secret-type-mismatch-imagepull-broken${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f - || {
  echo "setup.sh: failed to create/apply namespace $QUESTION_ID" >&2
  exit 1
}
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# Deliberately broken: a generic Opaque secret holding a dockerconfigjson-
# shaped payload under the wrong key name ('creds' instead of
# '.dockerconfigjson') and the wrong type (Opaque instead of
# kubernetes.io/dockerconfigjson).
#
# The container image itself is a real, publicly pullable image so the
# grading environment (an offline/minikube cluster with no real private
# registry to point at) can still exercise "fix the Secret, then the
# Deployment's rollout completes" end to end - the object under test is the
# Secret's type/key shape and the Deployment's imagePullSecrets reference,
# both of which check.sh grades directly against live cluster state.
#
# No "auth" field: check.sh only ever asserts .auths[...].username (never
# "auth"), and the candidate's fix replaces this Secret outright with
# `kubectl create secret docker-registry` (which computes its own auth),
# so the field would be dead weight here - and its real form is a base64
# blob that a secret scanner can't tell apart from a real credential.
RAW_DOCKERCONFIG='{"auths":{"registry.example.internal":{"username":"svc-deploy","password":"sample-registry-password","email":"svc-deploy@example.internal"}}}'

kubectl delete secret registry-cred -n "$QUESTION_ID" --ignore-not-found >/dev/null 2>&1

kubectl create secret generic registry-cred \
  --from-literal="creds=${RAW_DOCKERCONFIG}" \
  -n "$QUESTION_ID" >/dev/null
kubectl label secret registry-cred "clusterdrill-question=$QUESTION_ID" -n "$QUESTION_ID" --overwrite

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: private-app
  labels:
    app: private-app
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: private-app
  template:
    metadata:
      labels:
        app: private-app
        clusterdrill-question: $QUESTION_ID
    spec:
      imagePullSecrets:
        - name: registry-cred
      containers:
        - name: private-app
          image: nginx:1.25-alpine
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
EOF

echo "setup.sh: $QUESTION_ID ready"
