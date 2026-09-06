#!/usr/bin/env bash
# Idempotent: creates/resets namespace q102-36-adapter-missing-format-env
# and seeds a BROKEN Pod. "source" writes a raw CSV line to a shared
# emptyDir. "adapter" is supposed to read SOURCE_FORMAT from its own env to
# pick how to convert the raw line into JSON, but the env var is missing
# entirely from its container spec, so its script falls through to the
# passthrough default branch and writes the raw CSV line unchanged instead
# of converting it - "adapter" itself never crashes, it just produces the
# wrong output.
set -euo pipefail

QUESTION_ID="q102-36-adapter-missing-format-env${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

kubectl apply -n "$QUESTION_ID" -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: format-adapter
  labels:
    clusterdrill-question: q102-36-adapter-missing-format-env
spec:
  containers:
    - name: source
      image: busybox:1.36
      command: ["sh", "-c", "mkdir -p /data; echo 'sensor-7,42.5' > /data/raw.csv; while true; do sleep 3600; done"]
      volumeMounts:
        - name: shared
          mountPath: /data
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
    - name: adapter
      image: busybox:1.36
      command:
        - sh
        - -c
        - |
          i=0
          while [ $i -lt 60 ]; do
            if [ -f /data/raw.csv ]; then
              line="$(cat /data/raw.csv)"
              if [ "$SOURCE_FORMAT" = "csv" ]; then
                name="${line%%,*}"
                value="${line##*,}"
                printf '{"name":"%s","value":%s}\n' "$name" "$value" > /data/out.json
              else
                echo "$line" > /data/out.json
              fi
            fi
            i=$((i+1))
            sleep 3
          done
          while true; do sleep 3600; done
      volumeMounts:
        - name: shared
          mountPath: /data
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
  volumes:
    - name: shared
      emptyDir: {}
EOF

echo "setup.sh: q102-36-adapter-missing-format-env ready"
