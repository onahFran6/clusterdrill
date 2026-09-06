#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-03-configmap-from-env-file${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "ConfigMap 'worker-settings' exists" \
  resource_exists configmap worker-settings -n "$QUESTION_ID"

check_criterion "ConfigMap has LOG_LEVEL=debug as its own key" \
  [ "$(kget configmap worker-settings '{.data.LOG_LEVEL}' -n "$QUESTION_ID")" = "debug" ]

check_criterion "ConfigMap has MAX_CONNECTIONS=50 as its own key" \
  [ "$(kget configmap worker-settings '{.data.MAX_CONNECTIONS}' -n "$QUESTION_ID")" = "50" ]

check_criterion "ConfigMap has exactly 2 data keys (not the whole file under one key)" \
  [ "$(kget configmap worker-settings '{range .data.*}x{end}' -n "$QUESTION_ID")" = "xx" ]

print_score
