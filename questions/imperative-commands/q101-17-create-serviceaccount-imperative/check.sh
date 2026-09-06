#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q101-17-create-serviceaccount-imperative${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "ServiceAccount 'deploy-bot' exists in $QUESTION_ID" \
  resource_exists serviceaccount deploy-bot -n "$QUESTION_ID"

check_criterion "Pod 'bot-runner' exists in $QUESTION_ID" \
  resource_exists pod bot-runner -n "$QUESTION_ID"

check_criterion "Pod 'bot-runner' runs image 'busybox:1.36'" \
  [ "$(kget pod bot-runner '{.spec.containers[0].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

check_criterion "Pod 'bot-runner' uses ServiceAccount 'deploy-bot'" \
  [ "$(kget pod bot-runner '{.spec.serviceAccountName}' -n "$QUESTION_ID")" = "deploy-bot" ]

print_score
