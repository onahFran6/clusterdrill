#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
set -uo pipefail

QUESTION_ID="q105-14-immutable-configmap${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "ConfigMap 'release-info' is marked immutable" \
  [ "$(kget configmap release-info '{.immutable}' -n "$QUESTION_ID")" = "true" ]

check_criterion "The immutability is actually enforced by the API server" \
  bash -c "! kubectl patch configmap release-info -n '$QUESTION_ID' --type=merge -p '{\"data\":{\"VERSION\":\"9.9.9\"}}' --dry-run=server >/dev/null 2>&1"

print_score
