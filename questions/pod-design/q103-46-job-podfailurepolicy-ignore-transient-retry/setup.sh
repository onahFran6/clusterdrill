#!/usr/bin/env bash
# Idempotent: creates/resets namespace q103-46-job-podfailurepolicy-ignore-transient-retry, a
# PersistentVolumeClaim the container script uses to persist its attempt counter across pod
# recreations, and a Job seeded with suspend:true (and no podFailurePolicy) so it never actually
# consumes any of the PVC's counter budget before the candidate acts - keeping the unsolved state
# genuinely "never ran" rather than racing a real backoffLimit exhaustion during setup.sh itself.

set -euo pipefail

QUESTION_ID="q103-46-job-podfailurepolicy-ignore-transient-retry${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
kind: PersistentVolumeClaim
metadata:
  name: heartbeat-state
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 64Mi
EOF

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: heartbeat-sync
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  suspend: true
  backoffLimit: 1
  template:
    metadata:
      labels:
        clusterdrill-question: $QUESTION_ID
    spec:
      restartPolicy: Never
      volumes:
        - name: state
          persistentVolumeClaim:
            claimName: heartbeat-state
      containers:
        - name: heartbeat-sync
          image: busybox:1.36
          command:
            - sh
            - -c
            - |
              COUNT_FILE=/data/attempts
              [ -f "\$COUNT_FILE" ] || echo 0 > "\$COUNT_FILE"
              N=\$(( \$(cat "\$COUNT_FILE") + 1 ))
              echo "\$N" > "\$COUNT_FILE"
              if [ "\$N" -le 2 ]; then
                echo "dependency not ready yet (attempt \$N)"
                exit 75
              fi
              echo "dependency ready, syncing"
              exit 0
          volumeMounts:
            - name: state
              mountPath: /data
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
EOF

echo "setup.sh: $QUESTION_ID ready"
