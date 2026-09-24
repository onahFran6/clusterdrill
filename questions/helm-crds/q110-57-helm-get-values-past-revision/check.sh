#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q110-57-helm-get-values-past-revision${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

WORK_DIR="$(question_workdir "$QUESTION_ID")"
USER_FILE="$WORK_DIR/revision4-user.json"
ALL_FILE="$WORK_DIR/revision4-all.json"

check_criterion "revision4-user.json exists and contains buildTag=v4-hotfix" \
  bash -c '[ -f "$1" ] && grep -q "v4-hotfix" "$1"' _ "$USER_FILE"

check_criterion "revision4-user.json holds only the user-supplied override (no chart defaults)" \
  bash -c '[ -f "$1" ] && ! grep -q "us-east" "$1" && ! grep -q "1.25-alpine" "$1"' _ "$USER_FILE"

check_criterion "revision4-all.json exists and contains buildTag=v4-hotfix" \
  bash -c '[ -f "$1" ] && grep -q "v4-hotfix" "$1"' _ "$ALL_FILE"

check_criterion "revision4-all.json also contains the un-overridden chart defaults (region, image)" \
  bash -c '[ -f "$1" ] && grep -q "us-east" "$1" && grep -q "1.25-alpine" "$1"' _ "$ALL_FILE"

print_score
