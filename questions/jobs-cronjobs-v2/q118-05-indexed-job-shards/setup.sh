#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q118-05-indexed-job-shards${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

NS="$QUESTION_ID"
kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$NS" "clusterdrill-question=$NS" --overwrite
apply_default_resource_limits "$NS"
grant_user_namespace_access "$NS" "${CLUSTERDRILL_USER_ID:-}"
kubectl apply -n "$NS" -f - <<YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: shards
  namespace: $NS
  labels:
    clusterdrill-question: $NS
data:
  '0': ada,bola
  '1': chidi,dayo
  '2': emeka,funmi
YAML

echo "setup.sh: $QUESTION_ID ready"
