#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q106-41-secret-type-tls-basic${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Secret 'site-tls' exists and is type kubernetes.io/tls" \
  bash -c '
    kubectl get secret site-tls -n "'"$QUESTION_ID"'" >/dev/null 2>&1 || exit 1
    [ "$(kubectl get secret site-tls -n "'"$QUESTION_ID"'" -o jsonpath="{.type}")" = "kubernetes.io/tls" ]
  '

# Certs are self-signed by the candidate, so content differs every run - we
# can only check shape (non-empty PEM), not exact bytes.
check_criterion "Secret 'site-tls' key tls.crt decodes to a non-empty PEM certificate" \
  bash -c '
    crt="$(kubectl get secret site-tls -n "'"$QUESTION_ID"'" -o jsonpath="{.data.tls\.crt}" 2>/dev/null | base64 -d 2>/dev/null)"
    case "$crt" in
      "-----BEGIN CERTIFICATE-----"*) exit 0 ;;
      *) exit 1 ;;
    esac
  '

check_criterion "Secret 'site-tls' key tls.key decodes to a non-empty PEM private key" \
  bash -c '
    key="$(kubectl get secret site-tls -n "'"$QUESTION_ID"'" -o jsonpath="{.data.tls\.key}" 2>/dev/null | base64 -d 2>/dev/null)"
    case "$key" in
      "-----BEGIN"*"PRIVATE KEY-----"*) exit 0 ;;
      *) exit 1 ;;
    esac
  '

print_score
