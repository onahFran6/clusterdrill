#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q110-28-crd-finalizer-stuck-deletion${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

ARCHIVE_GONE="no"
if ! resource_exists archive cold-store-1 -n "$QUESTION_ID"; then
  ARCHIVE_GONE="yes"
fi
check_criterion "Archive 'cold-store-1' no longer exists in $QUESTION_ID" \
  [ "$ARCHIVE_GONE" = "yes" ]

# The CRD trivially still exists right after setup.sh (it's never touched
# until the candidate acts), so on its own that can't be a criterion - only
# "the CRD survived AND the stuck instance is actually gone" together prove
# the candidate unblocked cold-store-1 properly instead of deleting the
# whole CRD to force its instances away.
CRD_SURVIVED_PROPER_FIX="no"
if [ "$ARCHIVE_GONE" = "yes" ] && resource_exists crd archives.storage.clusterdrill.io; then
  CRD_SURVIVED_PROPER_FIX="yes"
fi
check_criterion "CRD 'archives.storage.clusterdrill.io' was left intact (finalizer removed, not the CRD deleted)" \
  [ "$CRD_SURVIVED_PROPER_FIX" = "yes" ]

print_score
