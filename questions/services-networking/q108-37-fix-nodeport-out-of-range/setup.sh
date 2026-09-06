#!/usr/bin/env bash
# The broken manifest is written to a file, never `kubectl apply`-d here: a
# nodePort outside the valid range is rejected by the API server at
# admission time, so "seeding" it live is impossible - the candidate's task
# is to fix the file and apply it themselves (same pattern as q107-34's
# deprecated-apiVersion file-based fix).
set -euo pipefail

QUESTION_ID="q108-37-fix-nodeport-out-of-range${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

WORK_DIR="$(question_workdir "$QUESTION_ID")"

cat >"$WORK_DIR/billing-svc.yaml" <<EOF
apiVersion: v1
kind: Service
metadata:
  name: billing-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  type: NodePort
  selector:
    app: billing
  ports:
    - port: 80
      targetPort: 80
      nodePort: 40090
EOF

echo "setup.sh: $QUESTION_ID ready (broken manifest at $WORK_DIR/billing-svc.yaml, not yet applied)"
