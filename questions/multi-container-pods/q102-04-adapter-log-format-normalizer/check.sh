#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-04-adapter-log-format-normalizer${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod has exactly 2 containers" \
  [ "$(kget pod app '{.spec.containers[*].name}' -n "$QUESTION_ID" | wc -w | tr -d ' ')" = "2" ]

ADAPTER_IMAGE="$(kget pod app '{.spec.containers[?(@.name=="adapter")].image}' -n "$QUESTION_ID")"
check_criterion "'adapter' container present with busybox image" \
  [ "$ADAPTER_IMAGE" = "busybox:1.36" ]

check_criterion "'adapter' mounts shared-data at /data" \
  [ "$(kget pod app '{.spec.containers[?(@.name=="adapter")].volumeMounts[?(@.name=="shared-data")].mountPath}' -n "$QUESTION_ID")" = "/data" ]

ADAPTER_CMD="$(kget pod app '{.spec.containers[?(@.name=="adapter")].command}' -n "$QUESTION_ID")"
check_criterion "'adapter' command reads raw.log" \
  bash -c "echo '$ADAPTER_CMD' | grep -q 'raw.log'"

check_criterion "'adapter' command writes normalized.log" \
  bash -c "echo '$ADAPTER_CMD' | grep -q 'normalized.log'"

print_score
