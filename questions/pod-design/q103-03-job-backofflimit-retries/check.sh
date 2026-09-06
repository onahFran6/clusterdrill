#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q103-03-job-backofflimit-retries${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# The unsolved starting state ships with backoffLimit: 50, so it will not
# reach Failed within a short wait - only a correctly-lowered backoffLimit of
# 2 fails this quickly. Keep the wait short (well under the time it'd take
# the default-50 Job to accumulate even a handful of exponential-backoff
# retries) so this criterion can't pass against the unsolved state just by
# the harness itself running long enough to let natural failures pile up.
job_gave_up_after_exactly_three_pods() {
  kubectl wait --for=condition=Failed job/flaky-task -n "$QUESTION_ID" --timeout=45s >/dev/null 2>&1 || return 1
  local count
  count="$(kubectl get pods -n "$QUESTION_ID" -l job-name=flaky-task --no-headers 2>/dev/null | wc -l | tr -d ' ')"
  [ "$count" = "3" ]
}

check_criterion "Job 'flaky-task' backoffLimit is set to 2" \
  [ "$(kget job flaky-task '{.spec.backoffLimit}' -n "$QUESTION_ID")" = "2" ]

check_criterion "Job 'flaky-task' reaches Failed after exactly 3 pod attempts (backoffLimit 2 -> 1 initial + 2 retries)" \
  job_gave_up_after_exactly_three_pods

print_score
