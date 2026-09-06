#!/usr/bin/env bash
# Idempotent: creates/resets namespace q105-40-secret-from-file-directory
# and seeds the ~/certs/ directory the candidate builds a Secret from. No
# cluster objects other than the namespace exist yet - the candidate
# authors the Secret.

set -euo pipefail

QUESTION_ID="q105-40-secret-from-file-directory${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

WORK_DIR="$(question_workdir "$QUESTION_ID")"
mkdir -p "$WORK_DIR/certs"
printf '%s' "CA-CERT-DATA" > "$WORK_DIR/certs/tls-ca.pem"
printf '%s' "CLIENT-CERT-DATA" > "$WORK_DIR/certs/tls-client.pem"

echo "setup.sh: $QUESTION_ID ready"
