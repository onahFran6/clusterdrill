#!/usr/bin/env bash
# Idempotent: creates/resets namespace and labels it to enforce the
# 'restricted' Pod Security Standard, then attempts to apply a Pod that
# runs as root with no other hardening - 'restricted' requires
# runAsNonRoot, allowPrivilegeEscalation: false, a RuntimeDefault/Localhost
# seccompProfile, and ALL capabilities dropped, so the API server's
# admission controller rejects this Pod at request time. That apply is
# EXPECTED to fail; this script must still exit 0.

set -uo pipefail

QUESTION_ID="q106-43-podsecurity-restricted-rejects-root${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f - || {
  echo "setup.sh: failed to create/apply namespace $QUESTION_ID" >&2
  exit 1
}
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
# The constraint the candidate must diagnose and work within: this
# namespace enforces the 'restricted' Pod Security Standard. Do not loosen
# this later - the check verifies it is still 'restricted' after.
kubectl label namespace "$QUESTION_ID" "pod-security.kubernetes.io/enforce=restricted" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# Deliberately non-compliant: no securityContext at all, so it inherits
# root and every other default 'restricted' forbids. This apply is
# EXPECTED to fail - do not let that abort setup.sh.
kubectl apply -n "$QUESTION_ID" -f - <<EOF || echo "setup.sh: expected admission rejection of unhardened 'audit-runner' pod (this is the bug the candidate must diagnose)"
apiVersion: v1
kind: Pod
metadata:
  name: audit-runner
  labels:
    app: audit-runner
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: audit-runner
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
EOF

echo "setup.sh: $QUESTION_ID ready"
