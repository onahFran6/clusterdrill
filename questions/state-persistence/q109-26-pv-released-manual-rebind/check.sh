#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q109-26-pv-released-manual-rebind${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

claimref_name="$(kget pv legacy-pv '{.spec.claimRef.name}')"
check_criterion "PV 'legacy-pv' claimRef is cleared or now points at recovered-claim" \
  bash -c '[[ "$1" != "legacy-claim" ]] && [[ -z "$1" || "$1" == "recovered-claim" ]]' _ "$claimref_name"

check_criterion "PersistentVolumeClaim 'recovered-claim' exists" \
  resource_exists pvc recovered-claim -n "$QUESTION_ID"

check_criterion "PVC 'recovered-claim' is Bound" \
  [ "$(kget pvc recovered-claim '{.status.phase}' -n "$QUESTION_ID")" = "Bound" ]

check_criterion "PVC 'recovered-claim' is bound to volume 'legacy-pv'" \
  [ "$(kget pvc recovered-claim '{.spec.volumeName}' -n "$QUESTION_ID")" = "legacy-pv" ]

print_score
