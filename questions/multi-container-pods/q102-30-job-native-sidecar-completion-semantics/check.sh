#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-30-job-native-sidecar-completion-semantics${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# In the unsolved state the Job runs forever (log-shipper as a regular
# container never exits), so this must be a bounded poll, not a single
# snapshot or an unbounded wait - 45s comfortably covers the fixed Job
# completing (observed ~15-20s on this cluster) without making the
# unsolved-state check.sh run needlessly long.
job_reached_complete() {
  resource_exists job log-shipping-job -n "$QUESTION_ID" || return 1
  kubectl wait --for=condition=Complete job/log-shipping-job -n "$QUESTION_ID" --timeout=45s >/dev/null 2>&1 || return 1
  [ "$(kget job log-shipping-job '{.status.succeeded}' -n "$QUESTION_ID")" = "1" ]
}

only_container_is_digest() {
  [ "$(kget job log-shipping-job '{.spec.template.spec.containers[*].name}' -n "$QUESTION_ID")" = "digest" ] || return 1
  [ "$(kget job log-shipping-job '{.spec.template.spec.containers[0].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]
}

check_criterion "Pod template has exactly 1 initContainers entry, named log-shipper" \
  [ "$(kget job log-shipping-job '{.spec.template.spec.initContainers[*].name}' -n "$QUESTION_ID")" = "log-shipper" ]

check_criterion "log-shipper initContainer has restartPolicy exactly Always (native sidecar)" \
  [ "$(kget job log-shipping-job '{.spec.template.spec.initContainers[0].restartPolicy}' -n "$QUESTION_ID")" = "Always" ]

check_criterion "log-shipper initContainer uses image busybox:1.36" \
  [ "$(kget job log-shipping-job '{.spec.template.spec.initContainers[0].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

check_criterion "Pod template has exactly 1 containers entry, named digest, image busybox:1.36" \
  only_container_is_digest

check_criterion "Job 'log-shipping-job' reaches Complete with succeeded=1" \
  job_reached_complete

print_score
