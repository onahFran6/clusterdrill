#!/usr/bin/env bash
# Idempotent: creates/resets namespace q102-24-restartpolicy-onfailure-sidecar-crashloop
# and seeds a BROKEN pod: "worker"'s loop script has a conditional
# (`if [ "$i" -ge 0 ]`) that always evaluates true starting from the very
# first iteration, so it always falls into a hardcoded `exit 1` about 10
# seconds after starting. Pod-level restartPolicy is OnFailure, so the
# kubelet keeps restarting "worker" in place; the native-sidecar init
# container "log-tailer" (restartPolicy: Always) gets churned along with it
# and its own restart count climbs too, losing log continuity.
set -euo pipefail

QUESTION_ID="q102-24-restartpolicy-onfailure-sidecar-crashloop${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: stream-proc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  restartPolicy: OnFailure
  initContainers:
    - name: log-tailer
      image: busybox:1.36
      restartPolicy: Always
      command: ["sh", "-c", "touch /data/app.log; tail -F /data/app.log"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
      volumeMounts:
        - name: shared-data
          mountPath: /data
  containers:
    - name: worker
      image: busybox:1.36
      command:
        - sh
        - -c
        - |
          i=0
          while true; do
            i=\$((i+1))
            echo "batch \$i processed" >> /data/app.log
            sleep 10
            if [ "\$i" -ge 0 ]; then
              exit 1
            fi
          done
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
      volumeMounts:
        - name: shared-data
          mountPath: /data
  volumes:
    - name: shared-data
      emptyDir: {}
EOF

echo "setup.sh: $QUESTION_ID ready"
