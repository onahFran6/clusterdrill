#!/usr/bin/env bash
# Idempotent: creates/resets namespace q101-36-create-secret-tls-imperative
# and seeds a self-signed cert/key pair in this question's terminal working
# directory for the candidate to build a TLS Secret from with
# `kubectl create secret tls`.

set -euo pipefail

QUESTION_ID="q101-36-create-secret-tls-imperative${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

kubectl create namespace "$QUESTION_ID" \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace "$QUESTION_ID" "clusterdrill-question=$QUESTION_ID" --overwrite
apply_default_resource_limits "$QUESTION_ID"
grant_user_namespace_access "$QUESTION_ID" "${CLUSTERDRILL_USER_ID:-}"

WORKDIR="$(question_workdir "$QUESTION_ID")"
openssl req -x509 -nodes -newkey rsa:2048 \
  -keyout "$WORKDIR/tls.key" -out "$WORKDIR/tls.crt" \
  -days 30 -subj "/CN=web.example.com" >/dev/null 2>&1

echo "setup.sh: $QUESTION_ID ready"
