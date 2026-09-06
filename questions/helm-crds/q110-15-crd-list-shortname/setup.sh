#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q110-15-crd-list-shortname${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

CRD_NAME="coupons.retail.clusterdrill.io"

kubectl apply -f - <<EOF
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: $CRD_NAME
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  group: retail.clusterdrill.io
  scope: Namespaced
  names:
    plural: coupons
    singular: coupon
    kind: Coupon
    listKind: CouponList
    shortNames:
      - cpn
  versions:
    - name: v1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              required:
                - discountPercent
              properties:
                discountPercent:
                  type: integer
EOF

kubectl wait --for=condition=Established "crd/$CRD_NAME" --timeout=60s

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: retail.clusterdrill.io/v1
kind: Coupon
metadata:
  name: spring-sale
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  discountPercent: 15
---
apiVersion: retail.clusterdrill.io/v1
kind: Coupon
metadata:
  name: flash-10
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  discountPercent: 10
---
apiVersion: retail.clusterdrill.io/v1
kind: Coupon
metadata:
  name: vip-20
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  discountPercent: 20
EOF

echo "setup.sh: $QUESTION_ID ready (3 Coupon instances seeded, short name 'cpn')"
