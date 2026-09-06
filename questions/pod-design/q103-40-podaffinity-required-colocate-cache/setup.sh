#!/usr/bin/env bash
# Idempotent: creates/resets namespace q103-40-podaffinity-required-colocate-cache, seeds a
# Running 'primary' pod, and writes an incomplete manifest for 'replica' (missing
# .spec.affinity.podAffinity entirely) to this question's terminal working directory. 'replica' is
# never applied here - unsolved state has NO replica pod at all (mirrors the q103-23 nodeName
# precedent for "unapplied manifest" questions).

set -euo pipefail

QUESTION_ID="q103-40-podaffinity-required-colocate-cache${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: primary
  labels:
    clusterdrill-question: $QUESTION_ID
    role: primary
spec:
  containers:
    - name: primary
      image: busybox:1.36
      command: ["sleep", "3600"]
      resources:
        requests: {cpu: 25m, memory: 32Mi}
        limits: {cpu: 50m, memory: 64Mi}
EOF

kubectl wait --for=condition=Ready pod/primary -n "$QUESTION_ID" --timeout=60s || true

WORK_DIR="$(question_workdir "$QUESTION_ID")"
cat > "$WORK_DIR/replica.yaml" <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: replica
  namespace: $QUESTION_ID
  labels:
    clusterdrill-question: $QUESTION_ID
    role: replica
spec:
  # TODO: add .spec.affinity.podAffinity with a
  # requiredDuringSchedulingIgnoredDuringExecution rule matching label
  # role: primary, topologyKey kubernetes.io/hostname, so this pod always
  # lands on the same node as 'primary'.
  containers:
    - name: replica
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

echo "setup.sh: $QUESTION_ID ready (incomplete manifest at $WORK_DIR/replica.yaml, not yet applied)"
