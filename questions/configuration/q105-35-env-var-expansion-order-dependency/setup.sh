#!/usr/bin/env bash
# Idempotent: creates/resets namespace
# q105-35-env-var-expansion-order-dependency and seeds a ConfigMap plus a
# Pod whose container 'builder' has a 4-variable $(VAR) expansion chain
# (BASE_DIR, REGION, ARCHIVE_PATH, FINAL_PATH) deliberately listed in the
# WRONG order - ARCHIVE_PATH comes before the two variables it references
# (BASE_DIR and REGION), so $(BASE_DIR) and $(REGION) are not yet defined
# when ARCHIVE_PATH is evaluated and it is left as a literal, unexpanded
# string. FINAL_PATH comes after ARCHIVE_PATH (so its own $(ARCHIVE_PATH)
# reference does resolve), but it inherits ARCHIVE_PATH's broken literal
# value, so the whole chain ends up wrong. Confirmed against real cluster
# behavior: $(VAR_NAME) expansion honors env-list order regardless of
# whether the referenced var is a plain `value` or `valueFrom.configMapKeyRef`
# - only the ORDER is broken here, not the sourcing method itself.
# Every object created here carries the label
# clusterdrill-question=q105-35-env-var-expansion-order-dependency
#.

set -euo pipefail

QUESTION_ID="q105-35-env-var-expansion-order-dependency${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# Deliberately broken: ARCHIVE_PATH (position 1) references $(BASE_DIR) and
# $(REGION), which are only defined at positions 2 and 3 - later in the
# list. Kubernetes only expands $(VAR_NAME) against variables defined
# earlier in the same env list, so ARCHIVE_PATH is left as the literal
# string "$(BASE_DIR)/$(REGION)/archive". FINAL_PATH (position 4) comes
# after ARCHIVE_PATH so its own $(ARCHIVE_PATH) reference does expand, but
# it just inherits ARCHIVE_PATH's already-broken literal value.
kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: region-config
  labels:
    clusterdrill-question: $QUESTION_ID
data:
  REGION: eu-west-1
---
apiVersion: v1
kind: Pod
metadata:
  name: path-builder
  labels:
    app: path-builder
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: builder
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      env:
        - name: ARCHIVE_PATH
          value: "\$(BASE_DIR)/\$(REGION)/archive"
        - name: BASE_DIR
          value: "/data"
        - name: REGION
          valueFrom:
            configMapKeyRef:
              name: region-config
              key: REGION
        - name: FINAL_PATH
          value: "\$(ARCHIVE_PATH)/current"
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
EOF

kubectl wait --for=condition=Ready pod/path-builder -n "$QUESTION_ID" --timeout=60s || true

echo "setup.sh: $QUESTION_ID ready"
