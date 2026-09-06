#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q110-30-crd-crossnamespace-count-and-cleanup${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SECOND_NS="${QUESTION_ID}-b"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

CRD_NAME="endpointprobes.monitoring.clusterdrill.io"
CRD_MIN="$(kget crd "$CRD_NAME" '{.spec.versions[0].schema.openAPIV3Schema.properties.spec.properties.intervalSeconds.minimum}')"
CRD_INTACT="no"
if resource_exists crd "$CRD_NAME" && [ "$CRD_MIN" = "5" ]; then
  CRD_INTACT="yes"
fi

# The two "invalid probe was deleted" criteria are computed first and
# reused below: on the unsolved state both probes are still present (as
# setup.sh left them), so CACHE_GONE/LEGACY_GONE are "no" and every
# criterion that requires them together with a valid probe's continued
# existence also fails - a candidate can't score by leaving everything
# untouched, only by doing the real selective-delete.
CACHE_GONE="no"
if ! resource_exists endpointprobe probe-cache -n "$SECOND_NS"; then
  CACHE_GONE="yes"
fi
check_criterion "Invalid probe 'probe-cache' (intervalSeconds 3) was deleted from $SECOND_NS" \
  [ "$CACHE_GONE" = "yes" ]

LEGACY_GONE="no"
if ! resource_exists endpointprobe probe-legacy -n "$SECOND_NS"; then
  LEGACY_GONE="yes"
fi
check_criterion "Invalid probe 'probe-legacy' (intervalSeconds 1) was deleted from $SECOND_NS" \
  [ "$LEGACY_GONE" = "yes" ]

API_OK="no"
if resource_exists endpointprobe probe-api -n "$QUESTION_ID" && [ "$CACHE_GONE" = "yes" ] && [ "$CRD_INTACT" = "yes" ]; then
  API_OK="yes"
fi
check_criterion "Valid probe 'probe-api' left untouched in $QUESTION_ID (selective delete, not a wipe)" \
  [ "$API_OK" = "yes" ]

WEB_OK="no"
if resource_exists endpointprobe probe-web -n "$QUESTION_ID" && [ "$LEGACY_GONE" = "yes" ] && [ "$CRD_INTACT" = "yes" ]; then
  WEB_OK="yes"
fi
check_criterion "Valid probe 'probe-web' left untouched in $QUESTION_ID (selective delete, not a wipe)" \
  [ "$WEB_OK" = "yes" ]

DB_OK="no"
if resource_exists endpointprobe probe-db -n "$SECOND_NS" && [ "$CACHE_GONE" = "yes" ] && [ "$LEGACY_GONE" = "yes" ] && [ "$CRD_INTACT" = "yes" ]; then
  DB_OK="yes"
fi
check_criterion "Valid probe 'probe-db' left untouched in $SECOND_NS (selective delete, not a namespace wipe)" \
  [ "$DB_OK" = "yes" ]

CRD_AND_PROGRESS_OK="no"
if [ "$CRD_INTACT" = "yes" ] && { [ "$CACHE_GONE" = "yes" ] || [ "$LEGACY_GONE" = "yes" ]; }; then
  CRD_AND_PROGRESS_OK="yes"
fi
check_criterion "CRD 'endpointprobes.monitoring.clusterdrill.io' was not deleted or weakened, and at least one invalid probe was actually deleted" \
  [ "$CRD_AND_PROGRESS_OK" = "yes" ]

print_score
