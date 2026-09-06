#!/usr/bin/env bash
# Idempotent: creates/resets namespace q102-44-init-container-secret-defaultmode-too-restrictive
# and seeds a Secret plus a BROKEN Pod. Init container "cert-loader" runs as
# non-root (securityContext.runAsUser: 1000, a deliberate hardening choice
# that must NOT be undone) and is supposed to copy the Secret's tls.key
# into a shared emptyDir so the main container never needs direct Secret
# access. But the Secret volume's defaultMode is 0000 - unreadable by
# anyone but the file's own root:root owner - so "cert-loader", running as
# UID 1000, gets Permission denied trying to read it. The copy command
# redirects that error away and the init container still exits 0 (nothing
# crashes, no CrashLoopBackOff), so the Pod proceeds straight to Running
# 1/1 - but /handoff/tls.key was never actually created.
set -euo pipefail

QUESTION_ID="q102-44-init-container-secret-defaultmode-too-restrictive${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
kind: Secret
metadata:
  name: tls-cert
  labels:
    clusterdrill-question: $QUESTION_ID
type: Opaque
stringData:
  tls.key: sekret-key-value-9931
EOF

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: cert-staging-app
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  initContainers:
    - name: cert-loader
      image: busybox:1.36
      securityContext:
        runAsUser: 1000
      command: ["sh", "-c", "cp /secret-in/tls.key /handoff/tls.key 2>/dev/null; echo staged"]
      volumeMounts:
        - name: cert
          mountPath: /secret-in
          readOnly: true
        - name: handoff
          mountPath: /handoff
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh", "-c", "while true; do sleep 3600; done"]
      volumeMounts:
        - name: handoff
          mountPath: /handoff
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
  volumes:
    - name: cert
      secret:
        secretName: tls-cert
        defaultMode: 0000
    - name: handoff
      emptyDir: {}
EOF

echo "setup.sh: $QUESTION_ID ready"
