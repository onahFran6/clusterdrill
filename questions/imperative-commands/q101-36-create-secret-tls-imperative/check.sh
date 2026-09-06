#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q101-36-create-secret-tls-imperative${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Secret 'web-tls' exists in $QUESTION_ID" \
  resource_exists secret web-tls -n "$QUESTION_ID"

check_criterion "Secret 'web-tls' is type kubernetes.io/tls" \
  bash -c "[ \"\$(kubectl get secret web-tls -n '$QUESTION_ID' -o jsonpath='{.type}' 2>/dev/null)\" = 'kubernetes.io/tls' ]"

check_criterion "Secret 'web-tls' has non-empty tls.crt and tls.key data keys" \
  bash -c "
    CRT=\$(kubectl get secret web-tls -n '$QUESTION_ID' -o jsonpath='{.data.tls\.crt}' 2>/dev/null)
    KEY=\$(kubectl get secret web-tls -n '$QUESTION_ID' -o jsonpath='{.data.tls\.key}' 2>/dev/null)
    [ -n \"\$CRT\" ] && [ -n \"\$KEY\" ]
  "

print_score
