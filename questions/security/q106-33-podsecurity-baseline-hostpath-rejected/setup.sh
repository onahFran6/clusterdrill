#!/usr/bin/env bash
# Idempotent: creates/resets namespace and labels it to enforce the 'baseline'
# Pod Security Standard, then attempts to apply a two-container Pod named
# 'log-relay' that shares a hostPath volume between its containers. 'baseline'
# forbids hostPath volumes outright, so the API server's admission controller
# rejects this Pod at request time - it never gets created. That apply is
# EXPECTED to fail; this script must still exit 0 and leave the namespace
# correctly labeled and ready for the candidate.

set -uo pipefail

QUESTION_ID="q106-33-podsecurity-baseline-hostpath-rejected${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f - || {
  echo "setup.sh: failed to create/apply namespace $QUESTION_ID" >&2
  exit 1
}
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
# The constraint the candidate must diagnose and work within: this namespace
# enforces the 'baseline' Pod Security Standard. Do not loosen this later -
# the check verifies it is still 'baseline' after the candidate is done.
kubectl label namespace "$QUESTION_ID" "pod-security.kubernetes.io/enforce=baseline" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# Deliberately broken: this Pod shares a hostPath volume between its two
# containers. 'baseline' forbids hostPath volumes entirely, so the API
# server's admission controller rejects the request outright and 'log-relay'
# never gets created - no Pod object exists at all, unlike a normal failure
# where a Pod exists but is unhealthy. This apply is EXPECTED to fail - do
# not let that abort setup.sh.
kubectl apply -n "$QUESTION_ID" -f - <<EOF || echo "setup.sh: expected admission rejection of hostPath 'log-relay' pod (this is the bug the candidate must diagnose)"
apiVersion: v1
kind: Pod
metadata:
  name: log-relay
  labels:
    app: log-relay
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: writer
      image: busybox:1.36
      command: ["sh", "-c", "echo hello-from-writer > /var/log/relay/relay.log && sleep 3600"]
      volumeMounts:
        - name: relay-log
          mountPath: /var/log/relay
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
    - name: reader
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      volumeMounts:
        - name: relay-log
          mountPath: /var/log/relay
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
  volumes:
    - name: relay-log
      hostPath:
        path: /tmp/q106-33-relay-log
        type: DirectoryOrCreate
EOF

echo "setup.sh: $QUESTION_ID ready"
