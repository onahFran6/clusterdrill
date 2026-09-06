#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q109-25-multi-container-subpath-partitioned-pvc${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'partitioned' exists in $QUESTION_ID" \
  resource_exists pod partitioned -n "$QUESTION_ID"

check_criterion "Pod 'partitioned' has containers writer-a and writer-b" \
  bash -c "[ \"\$(kubectl get pod partitioned -n '$QUESTION_ID' -o jsonpath='{.spec.containers[*].name}' 2>/dev/null | tr ' ' '\n' | sort | tr '\n' ' ')\" = 'writer-a writer-b ' ]"

check_criterion "Container 'writer-a' uses image busybox:1.36" \
  [ "$(kget pod partitioned '{.spec.containers[?(@.name=="writer-a")].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

check_criterion "Container 'writer-b' uses image busybox:1.36" \
  [ "$(kget pod partitioned '{.spec.containers[?(@.name=="writer-b")].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

check_criterion "Container 'writer-a' mounts shared-multi at /data with subPath section-a" \
  [ "$(kget pod partitioned '{.spec.containers[?(@.name=="writer-a")].volumeMounts[?(@.mountPath=="/data")].subPath}' -n "$QUESTION_ID")" = "section-a" ]

check_criterion "Container 'writer-b' mounts shared-multi at /data with subPath section-b" \
  [ "$(kget pod partitioned '{.spec.containers[?(@.name=="writer-b")].volumeMounts[?(@.mountPath=="/data")].subPath}' -n "$QUESTION_ID")" = "section-b" ]

check_criterion "Pod 'partitioned' volume is backed by PVC shared-multi" \
  bash -c "kubectl get pod partitioned -n '$QUESTION_ID' -o json 2>/dev/null | grep -q '\"shared-multi\"'"

check_criterion "Both containers of 'partitioned' are Ready" \
  bash -c "[ \"\$(kubectl get pod partitioned -n '$QUESTION_ID' -o jsonpath='{.status.containerStatuses[*].ready}' 2>/dev/null)\" = 'true true' ]"

check_criterion "writer-a sees only a.txt in /data (isolated from writer-b)" \
  bash -c "[ \"\$(kubectl exec -n '$QUESTION_ID' partitioned -c writer-a -- ls /data 2>/dev/null)\" = 'a.txt' ]"

check_criterion "writer-b sees only b.txt in /data (isolated from writer-a)" \
  bash -c "[ \"\$(kubectl exec -n '$QUESTION_ID' partitioned -c writer-b -- ls /data 2>/dev/null)\" = 'b.txt' ]"

print_score
