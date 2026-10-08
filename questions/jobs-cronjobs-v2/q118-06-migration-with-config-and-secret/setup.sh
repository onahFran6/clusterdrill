#!/usr/bin/env bash
set -euo pipefail

QUESTION_ID="q118-06-migration-with-config-and-secret${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
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
  name: migrate-config
  namespace: $NS
  labels:
    clusterdrill-question: $NS
data:
  DB_HOST: db.neptune.svc
  TARGET_VERSION: '42'
---
apiVersion: v1
kind: Secret
metadata:
  name: db-creds
  namespace: $NS
  labels:
    clusterdrill-question: $NS
type: Opaque
stringData:
  user: migrator
  password: s3cr3t
YAML

echo "setup.sh: $QUESTION_ID ready"
