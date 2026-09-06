#!/usr/bin/env bash
# No "set -e" - a failed criterion is a normal result, not a script error.
set -uo pipefail

QUESTION_ID="q109-28-readwriteoncepod-exclusive-mount${CLUSTERDRILL_NAMESPACE_SUFFIX:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../../lib/grading.sh"

check_criterion "PersistentVolume 'exclusive-pv' exists" \
  resource_exists pv exclusive-pv

check_criterion "PV 'exclusive-pv' capacity is 50Mi" \
  [ "$(kget pv exclusive-pv '{.spec.capacity.storage}')" = "50Mi" ]

check_criterion "PV 'exclusive-pv' hostPath is /tmp/ckad-exclusive-pv" \
  [ "$(kget pv exclusive-pv '{.spec.hostPath.path}')" = "/tmp/ckad-exclusive-pv" ]

check_criterion "PV 'exclusive-pv' storageClassName is empty string" \
  bash -c "kubectl get pv exclusive-pv >/dev/null 2>&1 && [ \"\$(kubectl get pv exclusive-pv -o jsonpath='{.spec.storageClassName}' 2>/dev/null)\" = '' ]"

check_criterion "PV 'exclusive-pv' accessModes is exactly [ReadWriteOncePod]" \
  [ "$(kget pv exclusive-pv '{.spec.accessModes}')" = '["ReadWriteOncePod"]' ]

check_criterion "PVC 'exclusive-claim' exists in $QUESTION_ID" \
  resource_exists pvc exclusive-claim -n "$QUESTION_ID"

check_criterion "PVC 'exclusive-claim' storageClassName is empty string" \
  bash -c "kubectl get pvc exclusive-claim -n '$QUESTION_ID' >/dev/null 2>&1 && [ \"\$(kubectl get pvc exclusive-claim -n '$QUESTION_ID' -o jsonpath='{.spec.storageClassName}' 2>/dev/null)\" = '' ]"

check_criterion "PVC 'exclusive-claim' accessModes is exactly [ReadWriteOncePod]" \
  [ "$(kget pvc exclusive-claim '{.spec.accessModes}' -n "$QUESTION_ID")" = '["ReadWriteOncePod"]' ]

check_criterion "PVC 'exclusive-claim' requests 50Mi" \
  [ "$(kget pvc exclusive-claim '{.spec.resources.requests.storage}' -n "$QUESTION_ID")" = "50Mi" ]

check_criterion "PVC 'exclusive-claim' is Bound to exclusive-pv" \
  [ "$(kget pvc exclusive-claim '{.status.phase}' -n "$QUESTION_ID")" = "Bound" ] && \
  [ "$(kget pvc exclusive-claim '{.spec.volumeName}' -n "$QUESTION_ID")" = "exclusive-pv" ]

check_criterion "Pod 'owner-pod' exists in $QUESTION_ID" \
  resource_exists pod owner-pod -n "$QUESTION_ID"

check_criterion "Pod 'owner-pod' references PVC exclusive-claim" \
  bash -c "kubectl get pod owner-pod -n '$QUESTION_ID' -o jsonpath='{.spec.volumes[*].persistentVolumeClaim.claimName}' 2>/dev/null | grep -qx 'exclusive-claim'"

check_criterion "Pod 'owner-pod' mounts the exclusive-claim volume at /data" \
  bash -c "
    vol=\$(kubectl get pod owner-pod -n '$QUESTION_ID' -o jsonpath='{.spec.volumes[?(@.persistentVolumeClaim.claimName==\"exclusive-claim\")].name}' 2>/dev/null)
    [ -n \"\$vol\" ] || exit 1
    mp=\$(kubectl get pod owner-pod -n '$QUESTION_ID' -o jsonpath=\"{.spec.containers[*].volumeMounts[?(@.name=='\$vol')].mountPath}\" 2>/dev/null)
    [ \"\$mp\" = \"/data\" ]
  "

check_criterion "Pod 'owner-pod' is Running" \
  [ "$(kget pod owner-pod '{.status.phase}' -n "$QUESTION_ID")" = "Running" ]

print_score
