#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q101-12-create-job-imperative${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Job 'hash-once' exists in $QUESTION_ID" \
  resource_exists job hash-once -n "$QUESTION_ID"

check_criterion "Job 'hash-once' uses image 'busybox:1.36'" \
  [ "$(kget job hash-once '{.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

check_criterion "Job 'hash-once' command includes sha256sum" \
  bash -c "kubectl get job hash-once -n '$QUESTION_ID' -o jsonpath='{.spec.template.spec.containers[0].args[*]}{.spec.template.spec.containers[0].command[*]}' 2>/dev/null | grep -q sha256sum"

check_criterion "Job 'hash-once' completed successfully" \
  [ "$(kget job hash-once '{.status.succeeded}' -n "$QUESTION_ID")" = "1" ]

print_score
