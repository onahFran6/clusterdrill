#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q118-17-timestamped-backups-no-overlap${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

NS="$QUESTION_ID"
kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$NS" "clusterdrill-question=$NS" --overwrite
apply_default_resource_limits "$NS"
grant_user_namespace_access "$NS" "${CLUSTERDRILL_USER_ID:-}"
kubectl apply -n "$NS" -f - <<YAML
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: notes
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  replicas: 1
  selector:
    matchLabels:
      app: notes
  template:
    metadata:
      labels:
        app: notes
    spec:
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: data
      containers:
      - name: notes
        image: busybox:1.36
        command:
        - sh
        - -c
        - while true; do date >> /data/notes.log; sleep 10; done
        volumeMounts:
        - name: data
          mountPath: /data
YAML
kubectl rollout status deployment/notes -n "$NS" --timeout=120s

echo "setup.sh: $QUESTION_ID ready"
