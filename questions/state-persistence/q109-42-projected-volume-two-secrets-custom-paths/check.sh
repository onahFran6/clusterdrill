#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q109-42-projected-volume-two-secrets-custom-paths${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'multi-secret-reader' exists and is Running" \
  bash -c "[ \"\$(kubectl get pod multi-secret-reader -n '$QUESTION_ID' -o jsonpath='{.status.phase}' 2>/dev/null)\" = 'Running' ]"

check_criterion "File /etc/creds/db/password contains 'hunter2'" \
  bash -c "[ \"\$(kubectl exec multi-secret-reader -n '$QUESTION_ID' -- cat /etc/creds/db/password 2>/dev/null)\" = 'hunter2' ]"

check_criterion "File /etc/creds/api/token contains 'abc123'" \
  bash -c "[ \"\$(kubectl exec multi-secret-reader -n '$QUESTION_ID' -- cat /etc/creds/api/token 2>/dev/null)\" = 'abc123' ]"

check_criterion "Volume 'creds' is a single projected volume combining both Secret sources" \
  bash -c "
    kubectl get pod multi-secret-reader -n '$QUESTION_ID' -o jsonpath='{.spec.volumes[?(@.name==\"creds\")].projected.sources[0].secret.name}' | grep -qE 'db-credentials|api-credentials' && \
    kubectl get pod multi-secret-reader -n '$QUESTION_ID' -o jsonpath='{.spec.volumes[?(@.name==\"creds\")].projected.sources[1].secret.name}' | grep -qE 'db-credentials|api-credentials'
  "

print_score
