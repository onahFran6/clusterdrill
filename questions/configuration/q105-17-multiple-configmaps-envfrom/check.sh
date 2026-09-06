#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-17-multiple-configmaps-envfrom${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'api-gateway' has an envFrom source referencing db-config" \
  bash -c "kubectl get pod api-gateway -n '$QUESTION_ID' -o json 2>/dev/null | grep -q '\"db-config\"'"

check_criterion "Pod 'api-gateway' has an envFrom source referencing cache-config" \
  bash -c "kubectl get pod api-gateway -n '$QUESTION_ID' -o json 2>/dev/null | grep -q '\"cache-config\"'"

check_criterion "Container actually sees DB_HOST=db.internal" \
  [ "$(kubectl exec -n "$QUESTION_ID" api-gateway -- sh -c 'echo $DB_HOST' 2>/dev/null)" = "db.internal" ]

check_criterion "Container actually sees CACHE_HOST=cache.internal" \
  [ "$(kubectl exec -n "$QUESTION_ID" api-gateway -- sh -c 'echo $CACHE_HOST' 2>/dev/null)" = "cache.internal" ]

print_score
