#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q109-44-pv-nodeaffinity-mismatch-blocks-scheduling${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

NODE_NAME="$(kubectl get nodes -o jsonpath='{.items[0].metadata.labels.kubernetes\.io/hostname}')"

AFFINITY_VALUE="$(kget pv metrics-local-pv '{.spec.nodeAffinity.required.nodeSelectorTerms[0].matchExpressions[0].values[0]}')"
if [ "$AFFINITY_VALUE" = "$NODE_NAME" ]; then
  FIXED=0
else
  FIXED=1
fi

check_criterion "PV 'metrics-local-pv' nodeAffinity fixed to this cluster's real node ($NODE_NAME)" \
  [ "$FIXED" = "0" ]

check_criterion "Fix applied AND PV's other fields (local.path, capacity, accessMode, storageClassName) unchanged" \
  bash -c "[ '$FIXED' = '0' ] && \
    [ \"\$(kubectl get pv metrics-local-pv -o jsonpath='{.spec.local.path}')\" = '/mnt/q109-44-metrics' ] && \
    [ \"\$(kubectl get pv metrics-local-pv -o jsonpath='{.spec.capacity.storage}')\" = '100Mi' ] && \
    [ \"\$(kubectl get pv metrics-local-pv -o jsonpath='{.spec.accessModes[0]}')\" = 'ReadWriteOnce' ] && \
    [ \"\$(kubectl get pv metrics-local-pv -o jsonpath='{.spec.storageClassName}')\" = 'local-storage-q109-44' ]"

check_criterion "PVC 'metrics-claim' is Bound" \
  bash -c '
    for _ in $(seq 1 15); do
      phase="$(kubectl get pvc metrics-claim -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
      [ "$phase" = "Bound" ] && exit 0
      sleep 2
    done
    exit 1
  '

check_criterion "Pod 'metrics-collector' is Running" \
  bash -c '
    for _ in $(seq 1 15); do
      phase="$(kubectl get pod metrics-collector -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
      [ "$phase" = "Running" ] && exit 0
      sleep 2
    done
    exit 1
  '

print_score
