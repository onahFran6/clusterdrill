#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-18-three-way-pipeline-volume${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod 'pipeline-app' has exactly 3 containers" \
  [ "$(kget pod pipeline-app '{.spec.containers[*].name}' -n "$QUESTION_ID" | wc -w | tr -d ' ')" = "3" ]

check_criterion "'generator' mounts pipeline-data at /pipeline" \
  [ "$(kget pod pipeline-app '{.spec.containers[?(@.name=="generator")].volumeMounts[?(@.name=="pipeline-data")].mountPath}' -n "$QUESTION_ID")" = "/pipeline" ]

check_criterion "'processor' mounts pipeline-data at /pipeline" \
  [ "$(kget pod pipeline-app '{.spec.containers[?(@.name=="processor")].volumeMounts[?(@.name=="pipeline-data")].mountPath}' -n "$QUESTION_ID")" = "/pipeline" ]

check_criterion "'consumer' mounts pipeline-data at /pipeline" \
  [ "$(kget pod pipeline-app '{.spec.containers[?(@.name=="consumer")].volumeMounts[?(@.name=="pipeline-data")].mountPath}' -n "$QUESTION_ID")" = "/pipeline" ]

GENERATOR_CMD="$(kget pod pipeline-app '{.spec.containers[?(@.name=="generator")].command}' -n "$QUESTION_ID")"
check_criterion "'generator' command references stage1.txt" \
  bash -c "echo '$GENERATOR_CMD' | grep -q stage1.txt"

PROCESSOR_CMD="$(kget pod pipeline-app '{.spec.containers[?(@.name=="processor")].command}' -n "$QUESTION_ID")"
check_criterion "'processor' command references stage1.txt" \
  bash -c "echo '$PROCESSOR_CMD' | grep -q stage1.txt"

check_criterion "'processor' command references stage2.txt" \
  bash -c "echo '$PROCESSOR_CMD' | grep -q stage2.txt"

CONSUMER_CMD="$(kget pod pipeline-app '{.spec.containers[?(@.name=="consumer")].command}' -n "$QUESTION_ID")"
check_criterion "'consumer' command references stage2.txt" \
  bash -c "echo '$CONSUMER_CMD' | grep -q stage2.txt"

print_score
