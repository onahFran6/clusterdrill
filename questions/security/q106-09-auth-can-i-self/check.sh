#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q106-09-auth-can-i-self${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

EXPECTED="$(kubectl auth can-i create deployments -n "$QUESTION_ID")"

check_criterion "ConfigMap 'can-i-result' exists in $QUESTION_ID" \
  resource_exists configmap can-i-result -n "$QUESTION_ID"

check_criterion "ConfigMap 'can-i-result' key 'answer' matches the real can-i result ($EXPECTED)" \
  [ "$(kget configmap can-i-result '{.data.answer}' -n "$QUESTION_ID")" = "$EXPECTED" ]

print_score
