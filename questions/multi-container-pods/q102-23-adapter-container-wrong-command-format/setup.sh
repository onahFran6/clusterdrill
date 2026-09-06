#!/usr/bin/env bash
# Idempotent: creates/resets namespace and seeds the "legacy-bridge" pod
# whose "json-adapter" container has a BROKEN command - it writes the
# numeric field under the key "code" instead of "status", so /data/out.json
# never contains a "status" key even though the pod is Running 2/2 and
# out.json is being written to continuously from the very first tick.
set -euo pipefail

QUESTION_ID="q102-23-adapter-container-wrong-command-format${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: legacy-bridge
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: producer
      image: busybox:1.36
      command:
        - "sh"
        - "-c"
        - |
          i=0
          while true; do
            i=\$((i + 1))
            echo "user\$i|200|/api" >> /data/raw.log
            sleep 5
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
    - name: json-adapter
      image: busybox:1.36
      command:
        - "sh"
        - "-c"
        - |
          touch /data/raw.log
          while true; do
            LINE=\$(tail -n 1 /data/raw.log)
            USERF=\$(echo "\$LINE" | cut -d'|' -f1)
            CODEF=\$(echo "\$LINE" | cut -d'|' -f2)
            PATHF=\$(echo "\$LINE" | cut -d'|' -f3)
            if [ -n "\$USERF" ]; then
              echo "{\"user\":\"\$USERF\",\"code\":\$CODEF,\"path\":\"\$PATHF\"}" >> /data/out.json
            fi
            sleep 5
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
