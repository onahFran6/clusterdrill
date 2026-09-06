#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q110-20-crd-status-subresource${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "status.phase on 'nightly-backup' is 'Completed'" \
  [ "$(kget backupjob nightly-backup '{.status.phase}' -n "$QUESTION_ID")" = "Completed" ]

check_criterion "status.phase is 'Completed' AND spec.targetPath is unchanged ('/data/backups')" \
  [ "$(kget backupjob nightly-backup '{.status.phase}{"|"}{.spec.targetPath}' -n "$QUESTION_ID")" = "Completed|/data/backups" ]

print_score
