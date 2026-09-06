#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q106-10-auth-can-i-as-serviceaccount${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

EXPECTED="$(kubectl auth can-i delete deployments \
  --as="system:serviceaccount:${QUESTION_ID}:ci-deployer" \
  -n "$QUESTION_ID")"

check_criterion "ConfigMap 'delete-check' exists in $QUESTION_ID" \
  resource_exists configmap delete-check -n "$QUESTION_ID"

check_criterion "ConfigMap 'delete-check' key 'answer' matches the real can-i result ($EXPECTED)" \
  [ "$(kget configmap delete-check '{.data.answer}' -n "$QUESTION_ID")" = "$EXPECTED" ]

print_score
