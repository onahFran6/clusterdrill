#!/usr/bin/env bash
# Idempotent: creates/resets namespace q103-20 and seeds six pods - three
# labeled tier=backend (the selector match), two labeled tier=frontend, and
# one with no tier label at all, so the candidate's selector must neither
# under-match (miss a backend pod) nor over-match (touch a non-backend or
# unlabeled pod).

set -euo pipefail

QUESTION_ID="q103-20-bulk-label-pods-by-selector${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

# name:tier - empty tier means "no tier label at all" (sidecar-1).
for name_tier in "api-1:backend" "api-2:backend" "api-3:backend" "web-1:frontend" "web-2:frontend" "sidecar-1:"; do
  IFS=':' read -r name tier <<< "$name_tier"
  if [ -n "$tier" ]; then
    tier_label_line="    tier: $tier"
  else
    tier_label_line=""
  fi
  kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: $name
  labels:
$tier_label_line
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: $name
      image: busybox:1.36
      command: ["sleep", "3600"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
EOF
done

echo "setup.sh: $QUESTION_ID ready"
