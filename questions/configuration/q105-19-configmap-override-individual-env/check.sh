#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-19-configmap-override-individual-env${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'notifier' has an explicit env entry for TIMEOUT_SECONDS=90" \
  [ "$(kget pod notifier '{.spec.containers[0].env[?(@.name=="TIMEOUT_SECONDS")].value}' -n "$QUESTION_ID")" = "90" ]

check_criterion "Container sees the override (TIMEOUT_SECONDS=90) alongside the unaffected ConfigMap value (RETRY_COUNT=3)" \
  bash -c "[ \"\$(kubectl exec -n '$QUESTION_ID' notifier -- sh -c 'echo \$TIMEOUT_SECONDS' 2>/dev/null)\" = '90' ] && [ \"\$(kubectl exec -n '$QUESTION_ID' notifier -- sh -c 'echo \$RETRY_COUNT' 2>/dev/null)\" = '3' ]"

print_score
