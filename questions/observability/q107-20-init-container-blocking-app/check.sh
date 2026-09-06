#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q107-20-init-container-blocking-app${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Service 'config-svc' exists with selector app=report-gen" \
  [ "$(kget service config-svc '{.spec.selector.app}' -n "$QUESTION_ID")" = "report-gen" ]

check_criterion "Pod 'report-gen' has label app=report-gen" \
  [ "$(kget pod report-gen '{.metadata.labels.app}' -n "$QUESTION_ID")" = "report-gen" ]

check_criterion "Init container 'wait-for-config' terminated with reason Completed" \
  [ "$(kubectl get pod report-gen -n "$QUESTION_ID" -o jsonpath='{.status.initContainerStatuses[0].state.terminated.reason}' 2>/dev/null)" = "Completed" ]

check_criterion "Pod 'report-gen' is Running" \
  [ "$(kget pod report-gen '{.status.phase}' -n "$QUESTION_ID")" = "Running" ]

print_score
