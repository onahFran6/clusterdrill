#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q110-48-helm-post-delete-hook-cleanup${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "Deployment 'demo-archiver' was removed (release 'demo' uninstalled)" \
  bash -c "! kubectl get deployment demo-archiver -n '$QUESTION_ID' >/dev/null 2>&1"

check_criterion "post-delete hook Job 'demo-cleanup' exists and completed successfully" \
  [ "$(kget job demo-cleanup '{.status.succeeded}' -n "$QUESTION_ID")" = "1" ]

print_score
