#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q103-18-cronjob-fix-job-template${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

a_run_of_data_sync_completes() {
  # Trigger a fresh on-demand run so we don't have to wait up to a minute for
  # the schedule, then confirm that run actually completes with the fixed
  # image. check.sh can run more than once against the same state (e.g. this
  # verification harness runs it both before and after the fix), so always
  # clear out any probe Job left over from a previous check.sh run first -
  # otherwise `create job` silently no-ops against the stale name and this
  # criterion would judge the OLD probe instead of a fresh one.
  kubectl delete job data-sync-probe -n "$QUESTION_ID" --ignore-not-found --wait=true >/dev/null 2>&1
  kubectl create job data-sync-probe --from=cronjob/data-sync -n "$QUESTION_ID" >/dev/null 2>&1 || return 1
  kubectl wait --for=condition=Complete job/data-sync-probe -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1
}

check_criterion "CronJob 'data-sync' jobTemplate image is busybox:1.36" \
  [ "$(kget cronjob data-sync '{.spec.jobTemplate.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

check_criterion "A run of 'data-sync' actually completes with the fixed image" \
  a_run_of_data_sync_completes

print_score
