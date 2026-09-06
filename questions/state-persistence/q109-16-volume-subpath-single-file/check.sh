#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q109-16-volume-subpath-single-file${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'config-reader' exists in $QUESTION_ID" \
  resource_exists pod config-reader -n "$QUESTION_ID"

check_criterion "Pod 'config-reader' uses image busybox:1.36" \
  [ "$(kget pod config-reader '{.spec.containers[0].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

check_criterion "Pod 'config-reader' mounts a volume backed by PVC shared-storage" \
  bash -c "kubectl get pod config-reader -n '$QUESTION_ID' -o json 2>/dev/null | grep -q '\"shared-storage\"'"

check_criterion "The volumeMount into config-reader uses subPath: app.conf" \
  [ "$(kget pod config-reader '{.spec.containers[0].volumeMounts[0].subPath}' -n "$QUESTION_ID")" = "app.conf" ]

check_criterion "That volumeMount is at mountPath /etc/app.conf" \
  [ "$(kget pod config-reader '{.spec.containers[0].volumeMounts[0].mountPath}' -n "$QUESTION_ID")" = "/etc/app.conf" ]

check_criterion "Pod 'config-reader' is Ready" \
  [ "$(kget pod config-reader '{.status.containerStatuses[0].ready}' -n "$QUESTION_ID")" = "true" ]

check_criterion "/etc/app.conf inside config-reader contains exactly 'ready=true'" \
  bash -c "[ \"\$(kubectl exec -n '$QUESTION_ID' config-reader -- cat /etc/app.conf 2>/dev/null)\" = 'ready=true' ]"

check_criterion "/etc/app.conf inside config-reader is a regular file, not a directory" \
  bash -c "kubectl exec -n '$QUESTION_ID' config-reader -- test -f /etc/app.conf"

print_score
