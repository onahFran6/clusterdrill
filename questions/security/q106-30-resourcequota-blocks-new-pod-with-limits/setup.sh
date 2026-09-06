#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds a ResourceQuota
# 'team-quota' (requests.cpu: 500m, requests.memory: 256Mi) plus an
# 'existing-worker' Pod already consuming 400m cpu / 200Mi memory of that
# quota - leaving only 100m cpu / 56Mi memory of headroom for the
# candidate's new Deployment. Every object created here carries
# clusterdrill-question=$QUESTION_ID.

set -uo pipefail

QUESTION_ID="q106-30-resourcequota-blocks-new-pod-with-limits${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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

# The constraint the candidate must diagnose and work within: a namespace
# ResourceQuota tighter than the default one apply_default_resource_limits
# already applied (500m/256Mi vs the default 600m/320Mi), plus an existing
# Pod that already consumes most of it.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-quota
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  hard:
    requests.cpu: "500m"
    requests.memory: "256Mi"
EOF

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: existing-worker
  labels:
    app: existing-worker
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: existing-worker
      image: nginx:1.25-alpine
      resources:
        requests:
          cpu: "400m"
          memory: "200Mi"
        limits:
          cpu: "400m"
          memory: "200Mi"
EOF

echo "setup.sh: $QUESTION_ID ready"
