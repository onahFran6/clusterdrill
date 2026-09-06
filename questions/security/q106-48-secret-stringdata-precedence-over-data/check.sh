#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q106-48-secret-stringdata-precedence-over-data${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Secret 'app-secret' key PASSWORD decodes to fresh-pw (updated)" \
  [ "$(kubectl get secret app-secret -n "$QUESTION_ID" -o jsonpath='{.data.PASSWORD}' 2>/dev/null | base64 -d 2>/dev/null)" = "fresh-pw" ]

# Gated on the PASSWORD update having landed too - API_TOKEN unchanged is
# already true straight out of setup.sh regardless of what the candidate
# does, so checking it alone would be vacuously true before any fix.
check_criterion "Secret 'app-secret' key API_TOKEN is still token-abc (untouched by the targeted patch)" \
  bash -c '
    pw="$(kubectl get secret app-secret -n "'"$QUESTION_ID"'" -o jsonpath="{.data.PASSWORD}" 2>/dev/null | base64 -d 2>/dev/null)"
    [ "$pw" = "fresh-pw" ] || exit 1
    token="$(kubectl get secret app-secret -n "'"$QUESTION_ID"'" -o jsonpath="{.data.API_TOKEN}" 2>/dev/null | base64 -d 2>/dev/null)"
    [ "$token" = "token-abc" ]
  '

print_score
