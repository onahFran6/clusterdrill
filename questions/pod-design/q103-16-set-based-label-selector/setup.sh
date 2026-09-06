#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q103-16-set-based-label-selector${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

for name_region in "svc-us:us" "svc-eu:eu" "svc-apac:apac" "svc-legacy:legacy"; do
  IFS=':' read -r name region <<< "$name_region"
  kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: $name
  labels:
    region: $region
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: $name
      image: busybox:1.36
      command: ["sleep", "3600"]
EOF
done

echo "setup.sh: $QUESTION_ID ready"
