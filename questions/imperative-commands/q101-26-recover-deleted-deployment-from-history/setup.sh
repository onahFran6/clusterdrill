#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds an orphaned ReplicaSet
# (Deployment deleted with --cascade=orphan) that the candidate must adopt
# back under a recreated Deployment named catalog-svc.

set -euo pipefail

QUESTION_ID="q101-26-recover-deleted-deployment-from-history${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# Re-runs of setup.sh (e.g. a candidate hitting "reset") must start from the
# same orphaned-ReplicaSet state every time, not from whatever the candidate
# left behind (a recreated Deployment, extra pods, etc). Clear prior
# catalog-svc objects first so this script is truly idempotent.
kubectl delete deployment,replicaset -n "$QUESTION_ID" -l "app=catalog-svc" \
  --ignore-not-found --wait=true >/dev/null 2>&1 || true

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: catalog-svc
  labels:
    app: catalog-svc
    clusterdrill-question: $QUESTION_ID
spec:
  replicas: 3
  selector:
    matchLabels:
      app: catalog-svc
  template:
    metadata:
      labels:
        app: catalog-svc
    spec:
      containers:
        - name: catalog-svc
          image: httpd:2.4-alpine
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
EOF

kubectl rollout status deployment/catalog-svc -n "$QUESTION_ID" --timeout=90s

# Snapshot the pod names BEFORE orphaning the Deployment so check.sh can
# later prove the candidate adopted these exact pods rather than causing a
# fresh rollout. Written under the question's own terminal working
# directory (not a shared /tmp path) so no other question's setup.sh can
# collide with or overwrite it.
WORK_DIR="$(question_workdir "$QUESTION_ID")"
SNAPSHOT_FILE="$WORK_DIR/pre-delete-pod-names.txt"
kubectl get pods -n "$QUESTION_ID" -l "app=catalog-svc" \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | sort > "$SNAPSHOT_FILE"

# Now orphan the Deployment: the ReplicaSet and its 3 Pods survive with no
# owning Deployment left to reconcile them.
kubectl delete deployment catalog-svc -n "$QUESTION_ID" --cascade=orphan --wait=true

echo "setup.sh: $QUESTION_ID ready (catalog-svc Deployment orphaned; snapshot at $SNAPSHOT_FILE)"
