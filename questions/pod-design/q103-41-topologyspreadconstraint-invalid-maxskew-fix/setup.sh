#!/usr/bin/env bash
# Idempotent: creates/resets namespace q103-41-topologyspreadconstraint-invalid-maxskew-fix and
# writes a pod manifest with an API-rejected maxSkew: 0 to this question's terminal working
# directory. The manifest is deliberately never applied here - kubectl apply on it as-written fails
# validation entirely, so there is no live object to seed and the unsolved state has NO pod at all
# (mirrors the q103-23/q103-33 precedent for "unapplied manifest" questions).

set -euo pipefail

QUESTION_ID="q103-41-topologyspreadconstraint-invalid-maxskew-fix${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

WORK_DIR="$(question_workdir "$QUESTION_ID")"
cat > "$WORK_DIR/spread-worker.yaml" <<EOF
# REJECTED by the API server - maxSkew must be greater than zero:
#   error: Pod "spread-worker" is invalid: spec.topologySpreadConstraints[0].maxSkew:
#   Invalid value: 0: must be greater than zero
apiVersion: v1
kind: Pod
metadata:
  name: spread-worker
  namespace: $QUESTION_ID
  labels:
    clusterdrill-question: $QUESTION_ID
    app: spread-worker
spec:
  topologySpreadConstraints:
    - maxSkew: 0
      topologyKey: kubernetes.io/hostname
      whenUnsatisfiable: DoNotSchedule
      labelSelector:
        matchLabels:
          app: spread-worker
  containers:
    - name: spread-worker
      image: busybox:1.36
      command: ["sleep", "3600"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
EOF

echo "setup.sh: $QUESTION_ID ready (invalid manifest at $WORK_DIR/spread-worker.yaml, not yet applied)"
