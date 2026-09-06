#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-01-sidecar-log-shipper${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod has exactly 2 containers" \
  [ "$(kget pod writer-app '{.spec.containers[*].name}' -n "$QUESTION_ID" | wc -w | tr -d ' ')" = "2" ]

check_criterion "Container 'log-shipper' present with busybox image" \
  [ "$(kget pod writer-app '{.spec.containers[?(@.name=="log-shipper")].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

check_criterion "'log-shipper' mounts log-data at /var/log/app" \
  [ "$(kget pod writer-app '{.spec.containers[?(@.name=="log-shipper")].volumeMounts[?(@.name=="log-data")].mountPath}' -n "$QUESTION_ID")" = "/var/log/app" ]

LOG_SHIPPER_CMD="$(kget pod writer-app '{.spec.containers[?(@.name=="log-shipper")].command}' -n "$QUESTION_ID")"
check_criterion "'log-shipper' command tails the log file" \
  bash -c "echo '$LOG_SHIPPER_CMD' | grep -q tail"

LOG_SHIPPER_VOL_NAME="$(kget pod writer-app '{.spec.containers[?(@.name=="log-shipper")].volumeMounts[?(@.name=="log-data")].name}' -n "$QUESTION_ID")"
check_criterion "'log-shipper' mounts the same volume name as 'writer'" \
  [ -n "$LOG_SHIPPER_VOL_NAME" ]

print_score
