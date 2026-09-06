#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q101-42-patch-deployment-rollout-strategy${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'checkout-api' has strategy.rollingUpdate.maxSurge=1" \
  bash -c "[ \"\$(kubectl get deployment checkout-api -n '$QUESTION_ID' -o jsonpath='{.spec.strategy.rollingUpdate.maxSurge}' 2>/dev/null)\" = '1' ]"

check_criterion "Deployment 'checkout-api' has strategy.rollingUpdate.maxUnavailable=0" \
  bash -c "[ \"\$(kubectl get deployment checkout-api -n '$QUESTION_ID' -o jsonpath='{.spec.strategy.rollingUpdate.maxUnavailable}' 2>/dev/null)\" = '0' ]"

print_score
