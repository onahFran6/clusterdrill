#!/usr/bin/env bash
set -uo pipefail

QUESTION_ID="q114-06-storageclass-for-local-disks${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "StorageClass q114-06-local-disk exists, labeled, no-provisioner, WaitForFirstConsumer" \
  bash -c '
    label="$(kubectl get sc q114-06-local-disk -o jsonpath="{.metadata.labels.clusterdrill-question}" 2>/dev/null)"
    prov="$(kubectl get sc q114-06-local-disk -o jsonpath="{.provisioner}" 2>/dev/null)"
    mode="$(kubectl get sc q114-06-local-disk -o jsonpath="{.volumeBindingMode}" 2>/dev/null)"
    [ "$label" = "'"$QUESTION_ID"'" ] && [ "$prov" = "kubernetes.io/no-provisioner" ] && [ "$mode" = "WaitForFirstConsumer" ]
  '

check_criterion "PV q114-06-local-pv exists with exact spec and label" \
  bash -c '
    cap="$(kubectl get pv q114-06-local-pv -o jsonpath="{.spec.capacity.storage}" 2>/dev/null)"
    mode="$(kubectl get pv q114-06-local-pv -o jsonpath="{.spec.accessModes[0]}" 2>/dev/null)"
    sc="$(kubectl get pv q114-06-local-pv -o jsonpath="{.spec.storageClassName}" 2>/dev/null)"
    path="$(kubectl get pv q114-06-local-pv -o jsonpath="{.spec.local.path}" 2>/dev/null)"
    label="$(kubectl get pv q114-06-local-pv -o jsonpath="{.metadata.labels.clusterdrill-question}" 2>/dev/null)"
    [ "$cap" = "1Gi" ] && [ "$mode" = "ReadWriteOnce" ] && [ "$sc" = "q114-06-local-disk" ] \
      && [ "$path" = "/mnt/q114-06-data" ] && [ "$label" = "'"$QUESTION_ID"'" ]
  '

check_criterion "PV q114-06-local-pv's nodeAffinity matches a real cluster node" \
  bash -c '
    key="$(kubectl get pv q114-06-local-pv -o jsonpath="{.spec.nodeAffinity.required.nodeSelectorTerms[0].matchExpressions[0].key}" 2>/dev/null)"
    op="$(kubectl get pv q114-06-local-pv -o jsonpath="{.spec.nodeAffinity.required.nodeSelectorTerms[0].matchExpressions[0].operator}" 2>/dev/null)"
    val="$(kubectl get pv q114-06-local-pv -o jsonpath="{.spec.nodeAffinity.required.nodeSelectorTerms[0].matchExpressions[0].values[0]}" 2>/dev/null)"
    [ "$key" = "kubernetes.io/hostname" ] && [ "$op" = "In" ] || exit 1
    for n in $(kubectl get nodes -o jsonpath="{.items[*].metadata.name}"); do
      [ "$n" = "$val" ] && exit 0
    done
    exit 1
  '

check_criterion "PVC thames-claim uses class q114-06-local-disk and reaches Bound once a Pod uses it" \
  bash -c '
    sc="$(kubectl get pvc thames-claim -n "'"$QUESTION_ID"'" -o jsonpath="{.spec.storageClassName}" 2>/dev/null)"
    [ "$sc" = "q114-06-local-disk" ] || exit 1
    for i in $(seq 1 12); do
      phase="$(kubectl get pvc thames-claim -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)"
      [ "$phase" = "Bound" ] && exit 0
      sleep 5
    done
    exit 1
  '

check_criterion "Pod thames-app is Running" \
  bash -c '[ "$(kubectl get pod thames-app -n "'"$QUESTION_ID"'" -o jsonpath="{.status.phase}" 2>/dev/null)" = "Running" ]'

print_score
