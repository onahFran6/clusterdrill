#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q103-12-cronjob-manual-trigger${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

manual_job_completed() {
  kubectl wait --for=condition=Complete job/backup-job-manual -n "$QUESTION_ID" --timeout=60s >/dev/null 2>&1
}

check_criterion "Job 'backup-job-manual' exists in $QUESTION_ID" \
  resource_exists job backup-job-manual -n "$QUESTION_ID"

check_criterion "Job 'backup-job-manual' uses the CronJob's image (busybox:1.36)" \
  [ "$(kget job backup-job-manual '{.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

check_criterion "Job 'backup-job-manual' runs to completion" \
  manual_job_completed

print_score
