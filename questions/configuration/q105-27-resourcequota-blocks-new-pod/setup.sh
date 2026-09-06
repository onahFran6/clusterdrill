#!/usr/bin/env bash
# Idempotent: creates/resets namespace q105-27-resourcequota-blocks-new-pod
# with a ResourceQuota 'compute-quota' (requests.cpu=500m,
# requests.memory=512Mi) and a Deployment 'primary' already consuming
# cpu=400m/memory=400Mi (1 replica) - leaving only cpu=100m/memory=112Mi of
# headroom. A second Deployment manifest is left on disk at
# ~/sidecar-job.yaml requesting cpu=300m/memory=200Mi per container, which
# the quota will reject if applied unmodified.
#
# NOTE: this question's own ResourceQuota is the subject under test (its
# `used` values are graded), so apply_default_resource_limits is
# deliberately NOT called here - it would stack a second, tighter quota
# (requests.memory=320Mi) that 'primary' alone (400Mi) would already
# violate, breaking the scenario before the candidate does anything. This
# mirrors q105-12-limitrange-defaults / q105-21-limitrange-min-max-bounds,
# whose own ResourceQuota/LimitRange is likewise the graded object.

set -euo pipefail

QUESTION_ID="q105-27-resourcequota-blocks-new-pod${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  hard:
    requests.cpu: "500m"
    requests.memory: "512Mi"
    limits.cpu: "1"
    limits.memory: "1Gi"
    pods: "4"
EOF

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: primary
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 1
  selector:
    matchLabels:
      app: primary
  template:
    metadata:
      labels:
        app: primary
        clusterdrill-question: $QUESTION_ID
    spec:
      containers:
        - name: primary
          image: busybox:1.36
          command: ["sleep", "3600"]
          resources:
            requests:
              cpu: "400m"
              memory: "400Mi"
            limits:
              cpu: "400m"
              memory: "400Mi"
EOF

kubectl rollout status deployment/primary -n "$QUESTION_ID" --timeout=60s || true

# Left on disk for the candidate to diagnose and fix - not a cluster object
# itself, so it carries no clusterdrill-question label. Written into this
# question's own terminal working directory (mapped to ~ in the candidate's
# terminal) - see question_workdir() in lib/grading.sh.
WORK_DIR="$(question_workdir "$QUESTION_ID")"
cat > "$WORK_DIR/sidecar-job.yaml" <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sidecar-job
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sidecar-job
  template:
    metadata:
      labels:
        app: sidecar-job
    spec:
      containers:
        - name: sidecar-job
          image: busybox:1.36
          command: ["sleep", "3600"]
          resources:
            requests:
              cpu: "300m"
              memory: "200Mi"
            limits:
              cpu: "300m"
              memory: "200Mi"
EOF

echo "setup.sh: $QUESTION_ID ready"
