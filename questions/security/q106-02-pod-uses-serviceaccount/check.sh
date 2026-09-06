#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q106-02-pod-uses-serviceaccount${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'report-job' exists in $QUESTION_ID" \
  resource_exists pod report-job -n "$QUESTION_ID"

check_criterion "Pod 'report-job' runs image 'busybox:1.36'" \
  [ "$(kget pod report-job '{.spec.containers[0].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

check_criterion "Pod 'report-job' uses ServiceAccount 'report-runner'" \
  [ "$(kget pod report-job '{.spec.serviceAccountName}' -n "$QUESTION_ID")" = "report-runner" ]

print_score
