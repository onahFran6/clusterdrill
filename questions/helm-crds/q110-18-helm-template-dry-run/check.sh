#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q110-18-helm-template-dry-run${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "ConfigMap 'rendered-info' exists in $QUESTION_ID" \
  resource_exists configmap rendered-info -n "$QUESTION_ID"

check_criterion "ConfigMap 'rendered-info' has data.containerName=payload-runner" \
  [ "$(kget configmap rendered-info '{.data.containerName}' -n "$QUESTION_ID")" = "payload-runner" ]

check_criterion "ConfigMap 'rendered-info' exists and no Deployment exists in $QUESTION_ID (chart was never installed)" \
  bash -c '[ -n "$(kubectl get configmap rendered-info -n "$1" -o name 2>/dev/null)" ] && [ -z "$(kubectl get deployment -n "$1" -o name 2>/dev/null)" ]' _ "$QUESTION_ID"

print_score
