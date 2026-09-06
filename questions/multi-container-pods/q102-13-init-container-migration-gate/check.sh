#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q102-13-init-container-migration-gate${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Pod has exactly 1 init container" \
  [ "$(kget pod migrated-app '{.spec.initContainers[*].name}' -n "$QUESTION_ID" | wc -w | tr -d ' ')" = "1" ]

INIT_CMD="$(kget pod migrated-app '{.spec.initContainers[?(@.name=="run-migration")].command}' -n "$QUESTION_ID")"
check_criterion "init container command references migration.done" \
  bash -c "echo '$INIT_CMD' | grep -q migration.done"

check_criterion "init container mounts status-vol at /status" \
  [ "$(kget pod migrated-app '{.spec.initContainers[?(@.name=="run-migration")].volumeMounts[?(@.name=="status-vol")].mountPath}' -n "$QUESTION_ID")" = "/status" ]

check_criterion "main container mounts status-vol at /status" \
  [ "$(kget pod migrated-app '{.spec.containers[?(@.name=="main")].volumeMounts[?(@.name=="status-vol")].mountPath}' -n "$QUESTION_ID")" = "/status" ]

print_score
