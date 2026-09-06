#!/usr/bin/env bash
# Idempotent: creates/resets namespace q102-41-projected-volume-merge-missing-key
# and seeds a ConfigMap, a Secret, and a BROKEN Pod. Both containers mount
# ONE projected volume combining the ConfigMap and the Secret at
# /etc/combined. The projected volume's secret source uses an explicit
# "items" list - which means ONLY the keys named there are projected, not
# every key in the Secret automatically - and that list only names
# "api-key", leaving out "db-pass" entirely. So /etc/combined/app.conf and
# /etc/combined/api-key both show up fine, but /etc/combined/db-pass never
# exists in either container, even though the Secret itself really has that
# key. Nothing crashes - both containers idle and report Running the whole
# time.
set -euo pipefail

QUESTION_ID="q102-41-projected-volume-merge-missing-key${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
kind: ConfigMap
metadata:
  name: app-config
  labels:
    clusterdrill-question: $QUESTION_ID
data:
  app.conf: "loglevel=info"
---
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
  labels:
    clusterdrill-question: $QUESTION_ID
type: Opaque
stringData:
  api-key: sek-4471
  db-pass: dbp-9902
EOF

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: combined-config-app
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh", "-c", "while true; do sleep 3600; done"]
      volumeMounts:
        - name: combined
          mountPath: /etc/combined
          readOnly: true
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
    - name: sidecar-auditor
      image: busybox:1.36
      command: ["sh", "-c", "while true; do sleep 3600; done"]
      volumeMounts:
        - name: combined
          mountPath: /etc/combined
          readOnly: true
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
  volumes:
    - name: combined
      projected:
        sources:
          - configMap:
              name: app-config
              items:
                - key: app.conf
                  path: app.conf
          - secret:
              name: app-secret
              items:
                - key: api-key
                  path: api-key
EOF

echo "setup.sh: $QUESTION_ID ready"
