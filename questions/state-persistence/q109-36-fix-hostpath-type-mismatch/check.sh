#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q109-36-fix-hostpath-type-mismatch${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

TYPE="$(kget pod log-writer '{.spec.volumes[0].hostPath.type}' -n "$QUESTION_ID")"
if [ "$TYPE" = "Directory" ]; then
  FIXED=0
else
  FIXED=1
fi

check_criterion "Pod 'log-writer' hostPath.type fixed to 'Directory'" \
  [ "$FIXED" = "0" ]

check_criterion "Fix applied AND hostPath.path/mountPath unchanged (/mnt/q109-36-logs -> /var/log/app)" \
  bash -c "[ '$FIXED' = '0' ] && \
    [ \"\$(kubectl get pod log-writer -n '$QUESTION_ID' -o jsonpath='{.spec.volumes[0].hostPath.path}')\" = '/mnt/q109-36-logs' ] && \
    [ \"\$(kubectl get pod log-writer -n '$QUESTION_ID' -o jsonpath='{.spec.containers[0].volumeMounts[0].mountPath}')\" = '/var/log/app' ]"

check_criterion "Pod 'log-writer' is Running" \
  bash -c "[ \"\$(kubectl get pod log-writer -n '$QUESTION_ID' -o jsonpath='{.status.phase}' 2>/dev/null)\" = 'Running' ]"

print_score
