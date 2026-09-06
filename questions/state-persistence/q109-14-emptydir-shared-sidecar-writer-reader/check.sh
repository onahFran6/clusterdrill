#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q109-14-emptydir-shared-sidecar-writer-reader${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'relay' exists in $QUESTION_ID" \
  resource_exists pod relay -n "$QUESTION_ID"

volumes_json="$(kubectl get pod relay -n "$QUESTION_ID" -o jsonpath='{.spec.volumes}' 2>/dev/null)"

check_criterion "Pod has an emptyDir volume named 'shared-data'" \
  bash -c '[[ "$1" == *"\"name\":\"shared-data\""* && "$1" == *"\"emptyDir\""* ]]' _ "$volumes_json"

check_criterion "Container 'writer' mounts 'shared-data' at /data" \
  [ "$(kget pod relay '{.spec.containers[?(@.name=="writer")].volumeMounts[?(@.name=="shared-data")].mountPath}' -n "$QUESTION_ID")" = "/data" ]

check_criterion "Container 'reader' mounts 'shared-data' at /data" \
  [ "$(kget pod relay '{.spec.containers[?(@.name=="reader")].volumeMounts[?(@.name=="shared-data")].mountPath}' -n "$QUESTION_ID")" = "/data" ]

check_criterion "reader container can read 'hello' written by writer via shared volume" \
  bash -c '[ "$(kubectl exec relay -c reader -n "$1" -- cat /data/msg.txt 2>/dev/null)" = "hello" ]' _ "$QUESTION_ID"

print_score
