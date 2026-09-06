#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q103-17-job-ttl-after-finished${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

job_self_deletes_after_completion() {
  resource_exists job self-cleaning -n "$QUESTION_ID" || return 1
  local ttl
  ttl="$(kget job self-cleaning '{.spec.ttlSecondsAfterFinished}' -n "$QUESTION_ID")"
  [ "$ttl" = "10" ] || return 1

  kubectl wait --for=condition=Complete job/self-cleaning -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1 || return 1

  # TTL controller sweeps on its own schedule - give it a generous window
  # beyond the 10s TTL before concluding it never cleaned the Job up.
  local waited=0
  while resource_exists job self-cleaning -n "$QUESTION_ID"; do
    sleep 5
    waited=$((waited + 5))
    [ "$waited" -ge 60 ] && return 1
  done
  return 0
}

check_criterion "Job 'self-cleaning' has ttlSecondsAfterFinished=10 and is auto-deleted after completion" \
  job_self_deletes_after_completion

print_score
