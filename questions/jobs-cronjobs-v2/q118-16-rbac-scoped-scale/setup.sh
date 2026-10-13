#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q118-16-rbac-scoped-scale${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

NS="$QUESTION_ID"
kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$NS" "clusterdrill-question=$NS" --overwrite
apply_default_resource_limits "$NS"
grant_user_namespace_access "$NS" "${CLUSTERDRILL_USER_ID:-}"
kubectl apply -n "$NS" -f - <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: web
        image: nginx:1.27
YAML

echo "setup.sh: $QUESTION_ID ready"
