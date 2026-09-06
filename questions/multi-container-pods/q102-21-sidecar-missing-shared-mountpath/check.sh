#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-21-sidecar-missing-shared-mountpath${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

# 'shipper' having no volumeMounts at all is not a crash - its loop just
# echoes "waiting for file" forever, so the pod is already Running 2/2 in
# the unsolved state, and 'app's own mount/image were never touched by the
# bug either. Bundle ALL of these into one criterion with the actual mount
# fix so nothing scores until 'shipper' can genuinely see the log file.
SHIPPER_MOUNTPATH="$(kget pod audit-logger '{.spec.containers[?(@.name=="shipper")].volumeMounts[?(@.name=="audit-vol")].mountPath}' -n "$QUESTION_ID")"
APP_MOUNTPATH="$(kget pod audit-logger '{.spec.containers[?(@.name=="app")].volumeMounts[?(@.name=="audit-vol")].mountPath}' -n "$QUESTION_ID")"
SHIPPER_IMAGE="$(kget pod audit-logger '{.spec.containers[?(@.name=="shipper")].image}' -n "$QUESTION_ID")"
POD_PHASE="$(kget pod audit-logger '{.status.phase}' -n "$QUESTION_ID")"
READY_COUNT="$(kget pod audit-logger '{.status.containerStatuses[*].ready}' -n "$QUESTION_ID" | tr ' ' '\n' | grep -c '^true$')"

check_criterion "Pod Running 2/2, 'shipper' mounts audit-vol at /var/log/audit, 'app' untouched" \
  bash -c "[ '$POD_PHASE' = 'Running' ] && [ '$READY_COUNT' = '2' ] && [ '$SHIPPER_MOUNTPATH' = '/var/log/audit' ] && [ '$APP_MOUNTPATH' = '/var/log/audit' ] && [ '$SHIPPER_IMAGE' = 'busybox:1.36' ]"

check_criterion "exec into 'shipper' can cat /var/log/audit/app.log" \
  kubectl exec audit-logger -c shipper -n "$QUESTION_ID" -- cat /var/log/audit/app.log

print_score
