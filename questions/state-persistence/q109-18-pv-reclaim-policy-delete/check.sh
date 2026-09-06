#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q109-18-pv-reclaim-policy-delete${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "PersistentVolume 'scratch-pv' exists" \
  resource_exists pv scratch-pv

check_criterion "PV labeled clusterdrill-question=$QUESTION_ID" \
  [ "$(kget pv scratch-pv '{.metadata.labels.clusterdrill-question}')" = "$QUESTION_ID" ]

check_criterion "PV capacity is 50Mi" \
  [ "$(kget pv scratch-pv '{.spec.capacity.storage}')" = "50Mi" ]

check_criterion "PV access mode is ReadWriteOnce" \
  [ "$(kget pv scratch-pv '{.spec.accessModes[0]}')" = "ReadWriteOnce" ]

check_criterion "PV hostPath is /tmp/ckad-scratch-pv" \
  [ "$(kget pv scratch-pv '{.spec.hostPath.path}')" = "/tmp/ckad-scratch-pv" ]

check_criterion "PV reclaim policy is Delete" \
  [ "$(kget pv scratch-pv '{.spec.persistentVolumeReclaimPolicy}')" = "Delete" ]

print_score
