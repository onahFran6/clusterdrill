#!/usr/bin/env bash
# Idempotent: creates/resets namespace q103-34-pod-terminationgraceperiod-window and writes an
# incomplete pod manifest (missing terminationGracePeriodSeconds) to this question's terminal
# working directory. Never applied here - unsolved state has NO pod object at all (mirrors the
# q103-23 nodeName precedent for "unapplied manifest" questions).

set -euo pipefail

QUESTION_ID="q103-34-pod-terminationgraceperiod-window${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

WORK_DIR="$(question_workdir "$QUESTION_ID")"
cat > "$WORK_DIR/slow-shutdown.yaml" <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: slow-shutdown
  namespace: $QUESTION_ID
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  # TODO: add terminationGracePeriodSeconds: 90 here - this app needs up to
  # 90 seconds to shut down cleanly, longer than Kubernetes' 30-second default.
  containers:
    - name: slow-shutdown
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

echo "setup.sh: $QUESTION_ID ready (incomplete manifest at $WORK_DIR/slow-shutdown.yaml, not yet applied)"
