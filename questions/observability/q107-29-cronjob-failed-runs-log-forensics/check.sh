#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q107-29-cronjob-failed-runs-log-forensics${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "CronJob 'nightly-cleanup' has a 'data' volume backed by ConfigMap 'cleanup-manifest'" \
  [ "$(kget cronjob nightly-cleanup '{.spec.jobTemplate.spec.template.spec.volumes[?(@.name=="data")].configMap.name}' -n "$QUESTION_ID")" = "cleanup-manifest" ]

check_criterion "Container mounts the 'data' volume at /data" \
  [ "$(kget cronjob nightly-cleanup '{.spec.jobTemplate.spec.template.spec.containers[0].volumeMounts[?(@.name=="data")].mountPath}' -n "$QUESTION_ID")" = "/data" ]

a_fresh_run_of_nightly_cleanup_succeeds() {
  # Trigger a fresh on-demand run so we don't have to wait up to a minute
  # for the schedule, then confirm that run actually completes. check.sh
  # can run more than once against the same state (before and after the
  # fix), so always clear out any probe Job left over from a previous
  # check.sh run first - otherwise `create job` silently no-ops against the
  # stale name and this criterion would judge the OLD probe instead of a
  # fresh one.
  kubectl delete job nightly-cleanup-probe -n "$QUESTION_ID" --ignore-not-found --wait=true >/dev/null 2>&1
  kubectl create job nightly-cleanup-probe --from=cronjob/nightly-cleanup -n "$QUESTION_ID" >/dev/null 2>&1 || return 1
  kubectl wait --for=condition=Complete job/nightly-cleanup-probe -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1
}

check_criterion "A fresh run of 'nightly-cleanup' actually succeeds after the fix" \
  a_fresh_run_of_nightly_cleanup_succeeds

print_score
