#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q109-03-static-pv-hostpath${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "PersistentVolume 'q109-03-data-pv' exists" \
  resource_exists pv q109-03-data-pv

check_criterion "PV labeled clusterdrill-question=$QUESTION_ID" \
  [ "$(kget pv q109-03-data-pv '{.metadata.labels.clusterdrill-question}')" = "$QUESTION_ID" ]

check_criterion "PV capacity is 1Gi" \
  [ "$(kget pv q109-03-data-pv '{.spec.capacity.storage}')" = "1Gi" ]

check_criterion "PV access mode is ReadWriteOnce" \
  [ "$(kget pv q109-03-data-pv '{.spec.accessModes[0]}')" = "ReadWriteOnce" ]

check_criterion "PV hostPath is /mnt/q109-03-data" \
  [ "$(kget pv q109-03-data-pv '{.spec.hostPath.path}')" = "/mnt/q109-03-data" ]

check_criterion "PV storageClassName is manual" \
  [ "$(kget pv q109-03-data-pv '{.spec.storageClassName}')" = "manual" ]

check_criterion "PV reclaim policy is Retain" \
  [ "$(kget pv q109-03-data-pv '{.spec.persistentVolumeReclaimPolicy}')" = "Retain" ]

print_score
