#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-40-secret-from-file-directory${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Secret 'cert-bundle' exists" \
  resource_exists secret cert-bundle -n "$QUESTION_ID"

check_criterion "Secret 'cert-bundle' key tls-ca.pem = CA-CERT-DATA" \
  [ "$(kubectl get secret cert-bundle -n "$QUESTION_ID" -o jsonpath='{.data.tls-ca\.pem}' 2>/dev/null | base64 -d 2>/dev/null)" = "CA-CERT-DATA" ]

check_criterion "Secret 'cert-bundle' key tls-client.pem = CLIENT-CERT-DATA" \
  [ "$(kubectl get secret cert-bundle -n "$QUESTION_ID" -o jsonpath='{.data.tls-client\.pem}' 2>/dev/null | base64 -d 2>/dev/null)" = "CLIENT-CERT-DATA" ]

print_score
