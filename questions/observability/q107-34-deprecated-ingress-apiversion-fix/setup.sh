#!/usr/bin/env bash
# Idempotent: creates/resets namespace and writes a broken manifest (removed
# apiVersion) to this question's terminal working directory for the
# candidate to fix and apply. The manifest itself is never applied here -
# extensions/v1beta1 Ingress no longer exists as a registered kind on this
# cluster, so kubectl apply would simply fail; the seeded artifact is the
# file on disk, not a live object.
set -euo pipefail

QUESTION_ID="q107-34-deprecated-ingress-apiversion-fix${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
kind: Service
metadata:
  name: storefront-svc
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  selector:
    app: storefront
  ports:
    - port: 80
EOF

WORK_DIR="$(question_workdir "$QUESTION_ID")"
cat > "$WORK_DIR/q107-34-ingress.yaml" <<EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: storefront-ingress
  namespace: $QUESTION_ID
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  rules:
    - host: storefront.example.com
      http:
        paths:
          - path: /
            backend:
              serviceName: storefront-svc
              servicePort: 80
EOF

echo "setup.sh: $QUESTION_ID ready (broken manifest at $WORK_DIR/q107-34-ingress.yaml)"
