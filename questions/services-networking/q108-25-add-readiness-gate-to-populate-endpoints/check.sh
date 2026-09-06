#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q108-25-add-readiness-gate-to-populate-endpoints${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Container 'search-index' readinessProbe.httpGet.path is '/' and port is unchanged" \
  bash -c "[ \"\$(kubectl get deployment search-index -n '$QUESTION_ID' -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.path}' 2>/dev/null)\" = '/' ] && [ \"\$(kubectl get deployment search-index -n '$QUESTION_ID' -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.port}' 2>/dev/null)\" = '80' ]"

check_criterion "Service 'search-index-svc' has exactly 2 ready endpoint addresses" \
  bash -c "count=\$(kubectl get endpoints search-index-svc -n '$QUESTION_ID' -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null | wc -w | tr -d ' '); [ \"\$count\" = '2' ]"

print_score
