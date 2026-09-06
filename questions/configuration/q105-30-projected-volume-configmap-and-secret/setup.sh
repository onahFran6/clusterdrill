#!/usr/bin/env bash
# Idempotent: creates/resets namespace
# q105-30-projected-volume-configmap-and-secret and seeds a ConfigMap
# 'app-settings', a Secret 'app-secret-key', and a pod 'combiner' whose
# single projected volume deliberately references misspelled ConfigMap/
# Secret names so neither source resolves - the pod sits in
# ContainerCreating until the candidate fixes the source names. Every
# cluster object created here carries the label
# clusterdrill-question=q105-30-projected-volume-configmap-and-secret
#.

set -uo pipefail

QUESTION_ID="q105-30-projected-volume-configmap-and-secret${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-settings
  labels:
    clusterdrill-question: $QUESTION_ID
data:
  app.conf: "mode=production\ncache=enabled"
---
apiVersion: v1
kind: Secret
metadata:
  name: app-secret-key
  labels:
    clusterdrill-question: $QUESTION_ID
stringData:
  secret.key: sample-secret-value
EOF

# Deliberately broken: the projected volume's sources reference a
# misspelled ConfigMap name (app-settingz) and a misspelled Secret name
# (app-secretkey), neither of which exists - the kubelet cannot resolve
# the volume sources, so the pod is stuck in ContainerCreating. This is
# the bug the candidate must diagnose and fix by recreating the pod with
# corrected source names.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: combiner
  labels:
    app: combiner
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: combiner
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
      volumeMounts:
        - name: combined
          mountPath: /etc/combined
  volumes:
    - name: combined
      projected:
        sources:
          - configMap:
              name: app-settingz
          - secret:
              name: app-secretkey
EOF

echo "setup.sh: $QUESTION_ID ready"
