#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q109-24-local-pv-node-affinity${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "StorageClass 'local-storage' exists" \
  resource_exists storageclass local-storage

check_criterion "StorageClass labeled clusterdrill-question=$QUESTION_ID" \
  [ "$(kget storageclass local-storage '{.metadata.labels.clusterdrill-question}')" = "$QUESTION_ID" ]

check_criterion "StorageClass provisioner is kubernetes.io/no-provisioner" \
  [ "$(kget storageclass local-storage '{.provisioner}')" = "kubernetes.io/no-provisioner" ]

check_criterion "StorageClass volumeBindingMode is WaitForFirstConsumer" \
  [ "$(kget storageclass local-storage '{.volumeBindingMode}')" = "WaitForFirstConsumer" ]

check_criterion "PersistentVolume 'local-data-pv' exists" \
  resource_exists pv local-data-pv

check_criterion "PV labeled clusterdrill-question=$QUESTION_ID" \
  [ "$(kget pv local-data-pv '{.metadata.labels.clusterdrill-question}')" = "$QUESTION_ID" ]

check_criterion "PV capacity is 100Mi" \
  [ "$(kget pv local-data-pv '{.spec.capacity.storage}')" = "100Mi" ]

check_criterion "PV access mode is ReadWriteOnce" \
  [ "$(kget pv local-data-pv '{.spec.accessModes[0]}')" = "ReadWriteOnce" ]

check_criterion "PV volumeMode is Filesystem" \
  [ "$(kget pv local-data-pv '{.spec.volumeMode}')" = "Filesystem" ]

check_criterion "PV storageClassName is local-storage" \
  [ "$(kget pv local-data-pv '{.spec.storageClassName}')" = "local-storage" ]

check_criterion "PV local path is /mnt/ckad-local-data" \
  [ "$(kget pv local-data-pv '{.spec.local.path}')" = "/mnt/ckad-local-data" ]

# The node name is discovered live (not hardcoded) so this question works
# on any cluster, single- or multi-node - the candidate is expected to
# discover it themselves via `kubectl get nodes` too.
REAL_NODE_NAMES="$(kubectl get nodes -o jsonpath='{.items[*].metadata.name}')"
PV_AFFINITY_KEY="$(kget pv local-data-pv '{.spec.nodeAffinity.required.nodeSelectorTerms[0].matchExpressions[0].key}')"
PV_AFFINITY_OP="$(kget pv local-data-pv '{.spec.nodeAffinity.required.nodeSelectorTerms[0].matchExpressions[0].operator}')"
PV_AFFINITY_VALUE="$(kget pv local-data-pv '{.spec.nodeAffinity.required.nodeSelectorTerms[0].matchExpressions[0].values[0]}')"

check_criterion "PV nodeAffinity matches key kubernetes.io/hostname, operator In" \
  bash -c '[ "$1" = "kubernetes.io/hostname" ] && [ "$2" = "In" ]' _ "$PV_AFFINITY_KEY" "$PV_AFFINITY_OP"

node_value_is_real=1
for n in $REAL_NODE_NAMES; do
  if [ "$n" = "$PV_AFFINITY_VALUE" ]; then
    node_value_is_real=0
    break
  fi
done
check_criterion "PV nodeAffinity value is a real cluster node name" \
  [ "$node_value_is_real" -eq 0 ]

check_criterion "PersistentVolumeClaim 'local-data-claim' exists" \
  resource_exists pvc local-data-claim -n "$QUESTION_ID"

check_criterion "PVC storageClassName is local-storage" \
  [ "$(kget pvc local-data-claim '{.spec.storageClassName}' -n "$QUESTION_ID")" = "local-storage" ]

check_criterion "PVC requests 100Mi" \
  [ "$(kget pvc local-data-claim '{.spec.resources.requests.storage}' -n "$QUESTION_ID")" = "100Mi" ]

check_criterion "PVC is Bound" \
  [ "$(kget pvc local-data-claim '{.status.phase}' -n "$QUESTION_ID")" = "Bound" ]

check_criterion "PVC is bound to local-data-pv" \
  [ "$(kget pvc local-data-claim '{.spec.volumeName}' -n "$QUESTION_ID")" = "local-data-pv" ]

check_criterion "Pod 'local-consumer' exists" \
  resource_exists pod local-consumer -n "$QUESTION_ID"

check_criterion "Pod local-consumer uses image busybox:1.36" \
  [ "$(kget pod local-consumer '{.spec.containers[0].image}' -n "$QUESTION_ID")" = "busybox:1.36" ]

check_criterion "Pod local-consumer mounts local-data-claim at /data" \
  bash -c '
    claim="$(kubectl get pod local-consumer -n "$1" -o jsonpath="{.spec.volumes[?(@.persistentVolumeClaim.claimName==\"local-data-claim\")].name}")"
    [ -n "$claim" ] || exit 1
    mountpath="$(kubectl get pod local-consumer -n "$1" -o jsonpath="{.spec.containers[0].volumeMounts[?(@.name==\"$claim\")].mountPath}")"
    [ "$mountpath" = "/data" ]
  ' _ "$QUESTION_ID"

check_criterion "Pod local-consumer is Running" \
  [ "$(kget pod local-consumer '{.status.phase}' -n "$QUESTION_ID")" = "Running" ]

print_score
