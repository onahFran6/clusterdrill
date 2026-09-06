#!/usr/bin/env bash
# Idempotent: creates/resets namespace q103-47-combined-nodeaffinity-podantiaffinity-manifest and
# writes an incomplete pod manifest (missing .spec.affinity entirely) to this question's terminal
# working directory. Never applied here - unsolved state has NO pod object at all (mirrors the
# q103-23 nodeName precedent for "unapplied manifest" questions).

set -euo pipefail

QUESTION_ID="q103-47-combined-nodeaffinity-podantiaffinity-manifest${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

WORK_DIR="$(question_workdir "$QUESTION_ID")"
cat > "$WORK_DIR/constrained-worker.yaml" <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: constrained-worker
  namespace: $QUESTION_ID
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  # TODO: add .spec.affinity with BOTH:
  #   - nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution matching
  #     kubernetes.io/os In [linux]
  #   - podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution
  #     matching label app: legacy-worker, topologyKey kubernetes.io/hostname
  containers:
    - name: constrained-worker
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

echo "setup.sh: $QUESTION_ID ready (incomplete manifest at $WORK_DIR/constrained-worker.yaml, not yet applied)"
