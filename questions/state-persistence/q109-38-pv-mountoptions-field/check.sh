#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q109-38-pv-mountoptions-field${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "PV 'perf-data-pv' exists" \
  resource_exists pv perf-data-pv

check_criterion "PV mountOptions is exactly [noatime, nobarrier]" \
  [ "$(kget pv perf-data-pv '{.spec.mountOptions}')" = '["noatime","nobarrier"]' ]

check_criterion "PV capacity 1Gi, accessMode ReadWriteOnce, reclaimPolicy Retain" \
  bash -c "[ \"\$(kubectl get pv perf-data-pv -o jsonpath='{.spec.capacity.storage}')\" = '1Gi' ] && \
    [ \"\$(kubectl get pv perf-data-pv -o jsonpath='{.spec.accessModes[0]}')\" = 'ReadWriteOnce' ] && \
    [ \"\$(kubectl get pv perf-data-pv -o jsonpath='{.spec.persistentVolumeReclaimPolicy}')\" = 'Retain' ]"

check_criterion "PV hostPath at /mnt/q109-38-perf-data, storageClassName empty" \
  bash -c "[ \"\$(kubectl get pv perf-data-pv -o jsonpath='{.spec.hostPath.path}')\" = '/mnt/q109-38-perf-data' ] && \
    [ \"\$(kubectl get pv perf-data-pv -o jsonpath='{.spec.storageClassName}')\" = '' ]"

print_score
