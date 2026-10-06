#!/usr/bin/env bash
# Idempotent: creates/resets the namespace and seeds a bare single-container
# Pod writing logs internally (no shared volume yet) - adding sidecars that
# can see those logs is the exercise.
set -euo pipefail

QUESTION_ID="q112-09-add-sidecars-to-running-pod${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: legacy
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: app
      image: busybox:1.36
      command:
        - sh
        - -c
        - |
          mkdir -p /var/log/legacy
          i=0
          while true; do
            i=\$((i+1))
            echo "GET /item/\$i 200" >> /var/log/legacy/access.log
            [ \$((i % 3)) -eq 0 ] && echo "ERR timeout on item \$i" >> /var/log/legacy/error.log
            sleep 2
          done
EOF

echo "setup.sh: $QUESTION_ID ready"
