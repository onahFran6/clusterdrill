#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q106-35-secret-from-literal-two-keys${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Secret 'api-keys' exists and is type Opaque" \
  bash -c '
    kubectl get secret api-keys -n "'"$QUESTION_ID"'" >/dev/null 2>&1 || exit 1
    [ "$(kubectl get secret api-keys -n "'"$QUESTION_ID"'" -o jsonpath="{.type}")" = "Opaque" ]
  '

check_criterion "Secret 'api-keys' key PRIMARY_KEY decodes to primary-key-123" \
  [ "$(kubectl get secret api-keys -n "$QUESTION_ID" -o jsonpath='{.data.PRIMARY_KEY}' 2>/dev/null | base64 -d 2>/dev/null)" = "primary-key-123" ]

check_criterion "Secret 'api-keys' key SECONDARY_KEY decodes to backup-key-124" \
  [ "$(kubectl get secret api-keys -n "$QUESTION_ID" -o jsonpath='{.data.SECONDARY_KEY}' 2>/dev/null | base64 -d 2>/dev/null)" = "backup-key-124" ]

print_score
