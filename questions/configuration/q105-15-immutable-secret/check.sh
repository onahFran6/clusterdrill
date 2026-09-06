#!/usr/bin/env bash
# Grades ONLY live cluster state. No `set -e`.
# The enforcement probe below uses --dry-run=server so it validates the
# API server's rejection without ever actually mutating the Secret - a
# check.sh must never leave the cluster in a different state than it found it.
set -uo pipefail

QUESTION_ID="q105-15-immutable-secret${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Secret 'signing-key' is marked immutable" \
  [ "$(kget secret signing-key '{.immutable}' -n "$QUESTION_ID")" = "true" ]

check_criterion "The immutability is actually enforced by the API server" \
  bash -c "! kubectl patch secret signing-key -n '$QUESTION_ID' --type=merge -p '{\"stringData\":{\"KEY_ID\":\"key-2099-z\"}}' --dry-run=server >/dev/null 2>&1"

print_score
